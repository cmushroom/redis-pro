//
//  SSHRediStackClient.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/8/5.
//

import Foundation
import RediStack
import NIO
import NIOSSH
import Logging

extension RediStackClient {
    
    func getSSHConn() async throws -> RedisConnection {
        logger.info("create new ssh connection...")
        
        let bindHost = "127.0.0.1"
        let bindPort = 0
        let sshHost = self.redisModel.sshHost
        let sshPort = self.redisModel.sshPort
        let sshUser = self.redisModel.sshUser
        let sshPass = self.redisModel.sshPass
        let targetHost = self.redisModel.host
        let targetPort = self.redisModel.port
        let password = self.redisModel.password
        let db = self.redisModel.database
        
        return try await withUnsafeThrowingContinuation { continuation in
            self.logger.info("start get new redis ssh connection...")
            
            let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
            
            let bootstrap = ClientBootstrap(group: group)
                .channelInitializer { channel in
                    let _ = channel.pipeline.addHandlers([NIOSSHHandler(role: .client(.init(userAuthDelegate: UserPasswordDelegate(username: sshUser, password: sshPass), serverAuthDelegate: AcceptAllHostKeysDelegate())), allocator: channel.allocator, inboundChildChannelInitializer: nil), ErrorHandler()])
                    return channel.addBaseRedisHandlers()
                }
                .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
                .channelOption(ChannelOptions.socket(SocketOptionLevel(IPPROTO_TCP), TCP_NODELAY), value: 1)
            
            logger.info("connecting to ssh server, host: \(sshHost), user: \(sshUser)")
            let channelFuture = bootstrap.connect(host: sshHost, port: sshPort)
            
            channelFuture.whenFailure { error in
                self.logger.error("connect ssh server, error \(error)")
                continuation.resume(throwing: error)
            }
            
            
            channelFuture.whenSuccess { channel in
                self.logger.info("connect ssh server, host: \(sshHost), user: \(sshUser) success...")
                self.sshChannel = channel
                let server = PortForwardingServer(group: group,
                                                  bindHost: bindHost,
                                                  bindPort: bindPort) { inboundChannel in
                    // This block executes whenever a new inbound channel is received. We want to forward it to the peer.
                    // To do that, we have to begin by creating a new SSH channel of the appropriate type.
                    channel.pipeline.handler(type: NIOSSHHandler.self).flatMap { sshHandler in
                        let promise = inboundChannel.eventLoop.makePromise(of: Channel.self)
                        let directTCPIP = SSHChannelType.DirectTCPIP(targetHost: targetHost,
                                                                     targetPort: targetPort,
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
                        
                        self.logger.info("forwarding channel create success...")
                        // We need to erase the channel here: we just want success or failure info.
                        return promise.futureResult.map { _ in }
                    }
                }
                
                self.sshServer = server
                
                // Run the server until complete
                self.logger.info("bind local server start...")
                let f:EventLoopFuture<Channel> = server.run()
                f.whenFailure { error in
                    self.logger.error("bind local server error: \(error)")
                    
                    let _ = channel.close()
                    let _ = server.close()
                    continuation.resume(throwing: error)
                }
                f.whenSuccess { localChannel in
                    let localBindPort:Int = localChannel.localAddress?.port ?? 0
                    self.logger.info("bind local server, port: \(bindPort), final: \(localBindPort), success...")
                    self.sshLocalChannel = localChannel
                    
                    var configuration: RedisConnection.Configuration
                    if (self.redisModel.password.isEmpty) {
                        configuration = try! RedisConnection.Configuration(hostname: bindHost, port: localBindPort, initialDatabase: db)
                    } else {
                        configuration = try! RedisConnection.Configuration(hostname: bindHost, port: localBindPort, password: password, initialDatabase: db)
                    }
                    
                    RedisConnection.make(
                        configuration: configuration
                        , boundEventLoop: MultiThreadedEventLoopGroup(numberOfThreads: 1).next()
                    ).whenComplete { completion in
                        if case .success(let r) = completion {
                            self.logger.info("init ssh redis connection success: \(r)")
                            self.connection = r
                            continuation.resume(returning: r)
                        }
                        else if case .failure(let error) = completion {
                            self.logger.error("init ssh redis connection error: \(error)")
                            
                            let _ = localChannel.close()
                            let _ = server.close()
                            let _ = channel.close()
                            continuation.resume(throwing: error)
                        }
                    }
                    //                    self.logger.info("ssh local bind channel init success, wait close...")
                    //                    try! localChannel.closeFuture.wait()
                }
            }
        }
        
    }
    
    
    func closeSSH() -> Void {
        if self.redisModel.connectionType == RedisConnectionTypeEnum.SSH.rawValue {
            self.logger.info("close ssh tunnel connection...")
            let _ = self.sshLocalChannel?.close()
            let _ = self.sshServer?.close()
            let _ = self.sshChannel?.close()
        }
        
        
    }
    
}


