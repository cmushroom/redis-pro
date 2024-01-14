//
//  ReconnectHandler.swift
//  redis-pro
//
//  Created by chengpan on 2024/1/13.
//

import Foundation
import NIO

class ReconnectHandler: ChannelInboundHandler {
    typealias InboundIn = ByteBuffer

    private var reconnectScheduled: Scheduled<Void>?
    private let reconnectInterval: TimeAmount

    init(reconnectInterval: TimeAmount) {
        self.reconnectInterval = reconnectInterval
    }

    func channelActive(context: ChannelHandlerContext) {
        print("Connection established")
        cancelReconnect()
    }

    func channelInactive(context: ChannelHandlerContext) {
        print("Connection closed. Will attempt to reconnect in \(reconnectInterval)")

        // Schedule a reconnect after the specified interval
        reconnectScheduled = context.eventLoop.scheduleTask(in: reconnectInterval) {
            self.reconnect(context: context)
        }
    }

    private func reconnect(context: ChannelHandlerContext) {
        print("Attempting to reconnect...")
//        let newBootstrap = makeBootstrap(context: context)
//        let newChannel = try! newBootstrap.connect(host: "your_server_host", port: your_server_port).wait()

        // Add handlers to the new channel as needed
        // ...

        print("Reconnection successful")
        context.fireChannelActive()
    }

    private func cancelReconnect() {
        reconnectScheduled?.cancel()
        reconnectScheduled = nil
    }

//    private func makeBootstrap(context: ChannelHandlerContext) -> ClientBootstrap {
//        // Configure and return a new bootstrap instance
//        // ...
//    }
}
