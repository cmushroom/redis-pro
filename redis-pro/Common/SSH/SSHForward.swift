//
//  SSHForward.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/8/5.
//

import Foundation
import NIO
import NIOSSH

final class PortForwardingServer {
    private var serverChannel: Channel?
    private let serverLoop: EventLoop
    private let group: EventLoopGroup
    private let bindHost: String
    private let bindPort: Int
    private let forwardingChannelConstructor: (Channel) -> EventLoopFuture<Void>

    init(group: EventLoopGroup,
         bindHost: String,
         bindPort: Int,
         _ forwardingChannelConstructor: @escaping (Channel) -> EventLoopFuture<Void>) {
        self.serverLoop = group.next()
        self.group = group
        self.forwardingChannelConstructor = forwardingChannelConstructor
        self.bindHost = bindHost
        self.bindPort = bindPort
    }

    func runClose() -> EventLoopFuture<Void> {
        ServerBootstrap(group: self.serverLoop, childGroup: self.group)
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelInitializer(self.forwardingChannelConstructor)
            .bind(host: String(self.bindHost), port: self.bindPort)
            .flatMap {
                self.serverChannel = $0
                return $0.closeFuture
            }
    }
    
    
    func run() -> EventLoopFuture<Channel> {
        let channelFuture = ServerBootstrap(group: self.serverLoop, childGroup: self.group)
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelInitializer(self.forwardingChannelConstructor)
            .bind(host: String(self.bindHost), port: self.bindPort)
        
        channelFuture.whenSuccess({channel in
            self.serverChannel = channel
        })
        return channelFuture
    }

    func close() -> EventLoopFuture<Void> {
        self.serverLoop.flatSubmit {
            guard let server = self.serverChannel else {
                // The server wasn't created yet, so we can just shut down straight away and let
                // the OS clean us up.
                return self.serverLoop.makeSucceededFuture(())
            }

            return server.close()
        }
    }
}

/// A simple handler that wraps data into SSHChannelData for forwarding.
final class SSHWrapperHandler: ChannelDuplexHandler {
    typealias InboundIn = SSHChannelData
    typealias InboundOut = ByteBuffer
    typealias OutboundIn = ByteBuffer
    typealias OutboundOut = SSHChannelData

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let data = self.unwrapInboundIn(data)

        guard case .channel = data.type, case .byteBuffer(let buffer) = data.data else {
            context.fireErrorCaught(SSHClientError.invalidData)
            return
        }

        context.fireChannelRead(self.wrapInboundOut(buffer))
    }

    func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        let data = self.unwrapOutboundIn(data)
        let wrapped = SSHChannelData(type: .channel, data: .byteBuffer(data))
        context.write(self.wrapOutboundOut(wrapped), promise: promise)
    }
}



final class GlueHandler {
    private var partner: GlueHandler?

    private var context: ChannelHandlerContext?

    private var pendingRead: Bool = false

    private init() {}
}

extension GlueHandler {
    static func matchedPair() -> (GlueHandler, GlueHandler) {
        let first = GlueHandler()
        let second = GlueHandler()

        first.partner = second
        second.partner = first

        return (first, second)
    }
}

extension GlueHandler {
    private func partnerWrite(_ data: NIOAny) {
        self.context?.write(data, promise: nil)
    }

    private func partnerFlush() {
        self.context?.flush()
    }

    private func partnerWriteEOF() {
        self.context?.close(mode: .output, promise: nil)
    }

    private func partnerCloseFull() {
        self.context?.close(promise: nil)
    }

    private func partnerBecameWritable() {
        if self.pendingRead {
            self.pendingRead = false
            self.context?.read()
        }
    }

    private var partnerWritable: Bool {
        self.context?.channel.isWritable ?? false
    }
}

extension GlueHandler: ChannelDuplexHandler {
    typealias InboundIn = NIOAny
    typealias OutboundIn = NIOAny
    typealias OutboundOut = NIOAny

    func handlerAdded(context: ChannelHandlerContext) {
        self.context = context

        // It's possible our partner asked if we were writable, before, and we couldn't answer.
        // Consider updating it.
        if context.channel.isWritable {
            self.partner?.partnerBecameWritable()
        }
    }

    func handlerRemoved(context: ChannelHandlerContext) {
        self.context = nil
        self.partner = nil
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        self.partner?.partnerWrite(data)
    }

    func channelReadComplete(context: ChannelHandlerContext) {
        self.partner?.partnerFlush()
    }

    func channelInactive(context: ChannelHandlerContext) {
        self.partner?.partnerCloseFull()
    }

    func userInboundEventTriggered(context: ChannelHandlerContext, event: Any) {
        if let event = event as? ChannelEvent, case .inputClosed = event {
            // We have read EOF.
            self.partner?.partnerWriteEOF()
        }
    }

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        self.partner?.partnerCloseFull()
    }

    func channelWritabilityChanged(context: ChannelHandlerContext) {
        if context.channel.isWritable {
            self.partner?.partnerBecameWritable()
        }
    }

    func read(context: ChannelHandlerContext) {
        if let partner = self.partner, partner.partnerWritable {
            context.read()
        } else {
            self.pendingRead = true
        }
    }
}
