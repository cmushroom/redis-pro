//
//  SSHRediStackClient.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/8/5.
//

import Foundation
import PromiseKit
import RediStack
import NIO
import NIOSSH
import Logging

extension RediStackClient {
    
    
    func getSSHConnection() -> Promise<RedisConnection> {
        logger.info("get ssh connection...")
        
        let bindHost = "127.0.0.1"
        let bindPort = 7778
        let sshHost = "192.168.15.120"
        let sshPort = 22
        let sshUser = "chengpanwang"
        let sshPass = "lovem"
        let targetHost = self.redisModel.host
        let targetPort = self.redisModel.port
        let password = self.redisModel.password
        let db = self.redisModel.database
        
        let promise = Promise<RedisConnection> { resolver in
            let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
            
            let bootstrap = ClientBootstrap(group: group)
                .channelInitializer { channel in
                    let _ = channel.pipeline.addHandlers([NIOSSHHandler(role: .client(.init(userAuthDelegate: UserPasswordDelegate(username: sshUser, password: sshPass), serverAuthDelegate: AcceptAllHostKeysDelegate())), allocator: channel.allocator, inboundChildChannelInitializer: nil), ErrorHandler()])
                    return channel.addBaseRedisHandlers()
                }
                .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
                .channelOption(ChannelOptions.socket(SocketOptionLevel(IPPROTO_TCP), TCP_NODELAY), value: 1)
            
            logger.info("connecting to ssh server...")
            let channelFuture = bootstrap.connect(host: sshHost, port: sshPort)
            
            channelFuture.whenFailure { error in
                self.logger.error("connect ssh server, error \(error)")
            }
            channelFuture.whenSuccess { channel in
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
            
                // Run the server until complete
                let f:EventLoopFuture<Channel> = server.run()
                f.whenSuccess { _ in
                    self.logger.info("..........")
                    let configuration = try! RedisConnection.Configuration(hostname: bindHost, port: bindPort, password: password, initialDatabase: db)
                    RedisConnection.make(
                        configuration: configuration
                        , boundEventLoop: MultiThreadedEventLoopGroup(numberOfThreads: 1).next()
                    ).whenComplete { completion in
                        if case .success(let r) = completion {
                            resolver.fulfill(r)
                        }
                        else if case .failure(let error) = completion {
                            self.logger.error("redis keys scan error \(error)")
                            resolver.reject(error)
                        }
                    }
                }
                
            }
        }
        
        return promise
    }
}
