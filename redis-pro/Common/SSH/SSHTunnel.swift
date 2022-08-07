//
//  SSHTunnel.swift
//  redis-pro
//
//  Created by chengpan on 2022/8/6.
//

import Foundation
import RediStack
import NIO
import NIOSSH
import Logging

class SSHTunnel {
    private let logger = Logger(label: "ssh-tunnel")
    let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    
    private var sshChannel:Channel?
    private var localForwardingChannel:Channel?
    private var forwardingServer:PortForwardingServer?
    
    private let bindHost = "127.0.0.1"
    private let bindPort = 0
    
    var sshHost:String
    var sshPort:Int
    var user:String
    var pass:String
    var targetHost:String
    var targetPort:Int
    
    init(sshHost: String, sshPort:Int, user:String, pass:String, targetHost:String, targetPort:Int) {
        self.sshHost = sshHost
        self.sshPort = sshPort
        self.user = user
        self.pass = pass
        self.targetHost = targetHost
        self.targetPort = targetPort
    }
    
    
    func openSSHTunnel() async throws -> Channel {
        logger.info("create new ssh connection...")
        
        return try await withCheckedThrowingContinuation { continuation in
            self.logger.info("init ssh tunnel start...")
            
            
            let bootstrap = ClientBootstrap(group: self.group)
                .channelInitializer { channel in
                    return channel.pipeline.addHandlers([NIOSSHHandler(role: .client(.init(userAuthDelegate: UserPasswordDelegate(username: self.user, password: self.pass), serverAuthDelegate: AcceptAllHostKeysDelegate())), allocator: channel.allocator, inboundChildChannelInitializer: nil), ErrorHandler()])
//                    return channel.pipeline.addBaseRedisHandlers()
                }
                .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
                .channelOption(ChannelOptions.socket(SocketOptionLevel(IPPROTO_TCP), TCP_NODELAY), value: 1)
            
            logger.info("connecting to ssh server, host: \(self.sshHost), user: \(self.user)")
            let channelFuture = bootstrap.connect(host: self.sshHost, port: self.sshPort)
            
            channelFuture.whenFailure { error in
                self.logger.error("connect ssh server error: \(error)")
                continuation.resume(throwing: error)
            }
            
            
            channelFuture.whenSuccess { channel in
                self.logger.info("connect ssh server success, host: \(self.sshHost), user: \(self.user)")
                self.sshChannel = channel
                let server = PortForwardingServer(group: self.group,
                                                  bindHost: self.bindHost,
                                                  bindPort: self.bindPort) { inboundChannel in
                    // This block executes whenever a new inbound channel is received. We want to forward it to the peer.
                    // To do that, we have to begin by creating a new SSH channel of the appropriate type.
                    channel.pipeline.handler(type: NIOSSHHandler.self).flatMap { sshHandler in
                        let promise = inboundChannel.eventLoop.makePromise(of: Channel.self)
                        let directTCPIP = SSHChannelType.DirectTCPIP(targetHost: self.targetHost,
                                                                     targetPort: self.targetPort,
                                                                     originatorAddress: inboundChannel.remoteAddress!)
                        sshHandler.createChannel(promise,
                                                 channelType: .directTCPIP(directTCPIP)) { childChannel, channelType in
                            guard case .directTCPIP = channelType else {
                                return channel.eventLoop.makeFailedFuture(SSHClientError.invalidChannelType)
                            }
                            
                            // Attach a pair of glue handlers, one in the inbound channel and one in the outbound one.
                            // We also add an error handler to both channels, and a wrapper handler to the SSH child channel to
                            // encapsulate the data in SSH messages.
                            // When the glue handlers are in, we can create both channels.
                            let (ours, theirs) = GlueHandler.matchedPair()
                            return childChannel.pipeline.addHandlers([SSHWrapperHandler(), ours, ErrorHandler()]).flatMap {
                                inboundChannel.pipeline.addHandlers([theirs, ErrorHandler()])
                            }
                        }
                        
                        self.logger.info("init new forwarding channel success...")
                        // We need to erase the channel here: we just want success or failure info.
                        return promise.futureResult.map { _ in }
                    }
                }
                
                self.forwardingServer = server
                
                // Run the server until complete
                self.logger.info("forwarding servier start...")
                let f:EventLoopFuture<Channel> = server.run()
                f.whenFailure { error in
                    self.logger.error("init forwarding channel error: \(error)")
                    self.close()
                    continuation.resume(throwing: error)
                }
                f.whenSuccess { localForwardingChannel in
                    self.localForwardingChannel = localForwardingChannel
                    continuation.resume(returning: localForwardingChannel)
                }
            }
        }
        
    }
    
//    func openSSH() async throws -> Channel {
//        return try await withCheckedThrowingContinuation { continuation in
//            let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
//
//            let bootstrap = ClientBootstrap(group: group)
//                .channelInitializer { channel in
//                    return channel.pipeline.addHandlers([NIOSSHHandler(role: .client(.init(userAuthDelegate: UserPasswordDelegate(username: self.user, password: self.pass), serverAuthDelegate: AcceptAllHostKeysDelegate())), allocator: channel.allocator, inboundChildChannelInitializer: nil), ErrorHandler()])
////                    return channel.pipeline.addBaseRedisHandlers()
//                }
//                .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
//                .channelOption(ChannelOptions.socket(SocketOptionLevel(IPPROTO_TCP), TCP_NODELAY), value: 1)
//
//            logger.info("connecting to ssh server, host: \(sshHost), user: \(user)")
//            let channelFuture = bootstrap.connect(host: self.sshHost, port: self.sshPort)
//
//            channelFuture.whenFailure { error in
//                self.logger.error("connect ssh server, error \(error)")
//                continuation.resume(throwing: error)
//            }
//
//
//            channelFuture.whenSuccess { channel in
//                self.logger.info("connect ssh server success, host: \(self.sshHost), user: \(self.user)")
//                self.sshChannel = channel
//                continuation.resume(returning: channel)
//            }
//        }
//    }
    
        
//    func open() async throws -> Channel {
//        logger.info("create ssh tunnel start...")
//        let group = MultiThreadedEventLoopGroup(numberOfThreads: 2)
//        let channel = try await openSSH()
//        return try await withCheckedThrowingContinuation { continuation in
//            let server = PortForwardingServer(group: group,
//                                              bindHost: self.bindHost,
//                                              bindPort: self.bindPort) { inboundChannel in
//                // This block executes whenever a new inbound channel is received. We want to forward it to the peer.
//                // To do that, we have to begin by creating a new SSH channel of the appropriate type.
//                channel.pipeline.handler(type: NIOSSHHandler.self).flatMap { sshHandler in
//                    let promise = inboundChannel.eventLoop.makePromise(of: Channel.self)
//                    let directTCPIP = SSHChannelType.DirectTCPIP(targetHost: self.targetHost,
//                                                                 targetPort: self.targetPort,
//                                                                 originatorAddress: inboundChannel.remoteAddress!)
//                    sshHandler.createChannel(promise,
//                                             channelType: .directTCPIP(directTCPIP)) { childChannel, channelType in
//                        guard case .directTCPIP = channelType else {
//                            return channel.eventLoop.makeFailedFuture(SSHClientError.invalidChannelType)
//                        }
//
//                        // Attach a pair of glue handlers, one in the inbound channel and one in the outbound one.
//                        // We also add an error handler to both channels, and a wrapper handler to the SSH child channel to
//                        // encapsulate the data in SSH messages.
//                        // When the glue handlers are in, we can create both channels.
//                        let (ours, theirs) = GlueHandler.matchedPair()
//                        return childChannel.pipeline.addHandlers([SSHWrapperHandler(), ours, ErrorHandler()]).flatMap {
//                            inboundChannel.pipeline.addHandlers([theirs, ErrorHandler()])
//                        }
//                    }
//
//                    self.logger.info("init new forwarding channel success...")
//                    // We need to erase the channel here: we just want success or failure info.
//                    return promise.futureResult.map { _ in }
//                }
//            }
//
//            self.forwardingServer = server
//
//            // Run the server until complete
//            self.logger.info("create forwarding server success...")
//            let localForwardingChannelFuture:EventLoopFuture<Channel> = server.run()
//            localForwardingChannelFuture.whenFailure { error in
//                self.logger.error("bind local server error: \(error)")
//
//                self.close()
//                continuation.resume(throwing: error)
//            }
//            localForwardingChannelFuture.whenSuccess { localForwardingChannel in
//                let localForwardingPort:Int = localForwardingChannel.localAddress?.port ?? 0
//                self.logger.info("ssh tunnel forwarding server start success, port: \(localForwardingPort)")
//                self.localForwardingChannel = localForwardingChannel
//                continuation.resume(returning: localForwardingChannel)
//            }
//        }
//
//    }
    
    func close() {
        let _ = self.localForwardingChannel?.close()
        let _ = self.forwardingServer?.close()
        let _ = self.sshChannel?.close()
    }
}


struct SSHTunnelAddress {
    var host:String
    var port:Int
}
