//
//  RedisClientConn.swift
//  redis-pro
//
//  Created by chengpan on 2023/7/23.
//

import Foundation
import RediStack
import NIO

// MARK: - conn operator
extension RediStackClient {
    
    /*
     * 初始化redis 连接
     */
    func initConnection() async -> Bool {
        begin()
        defer {
            complete()
        }
        
        do {
            let _ = try await getConn()
            return true
            
        } catch {
            handleError(error)
        }
        
        return false
    }
    
    /// test redis connection
    func testConn() async -> Bool {
        do {
            var conn:RedisConnection
            
            if self.redisModel.connectionType == RedisConnectionTypeEnum.SSH.rawValue {
                conn = try await initSSHConn()
            } else {
                conn = try await initConn(host: self.redisModel.host, port: self.redisModel.port, username: self.redisModel.username, pass: self.redisModel.password, database: self.redisModel.database)
            }
            
            defer {
                conn.close()
            }
            
            return try await _send(conn, .ping) == "PONG"
        } catch {
            Messages.show(error)
            return false
        }
    }
    
    func getConn() async throws -> RedisClient {
        if self.connPool != nil {
            return self.connPool!
        }
        return try await getConnPool()
    }
    
    func refreshConn() async {
        self.close()
        try! await self.getConn()
    }
    
    func getConnPool() async throws -> RedisClient {
        if self.connPool != nil {
            return self.connPool!
        } else {
            self.logger.info("get redis connection, but connection is not available...")
            self.close()
        }
        
        if self.redisModel.connectionType == RedisConnectionTypeEnum.SSH.rawValue {
            self.connPool = try await initSSHPool()
        } else {
            self.connPool = try initPool(host: self.redisModel.host, port: self.redisModel.port, username: self.redisModel.username, pass: self.redisModel.password, database: self.redisModel.database)
        }
        
        return self.connPool!
    }
    
    func initConn(host:String, port:Int,
                  username: String? = nil,
                  pass:String,
                  database:Int
    ) async throws -> RedisConnection {
        logger.info("redis client- init new redis connection, host: \(host), port: \(port), pass: \(pass), database: \(database)")
        return try await withCheckedThrowingContinuation { continuation in
            do {
                let eventLoop = MultiThreadedEventLoopGroup(numberOfThreads: 4).next()
                var configuration: RedisConnection.Configuration
                if (pass.isEmpty) {
                    configuration = try RedisConnection.Configuration(hostname: host, port: port, initialDatabase: database, defaultLogger: logger)
                } else {
                    let _username = username?.isEmpty ?? false ? nil : username
                    configuration = try RedisConnection.Configuration(hostname: host, port: port, username: _username, password: pass, initialDatabase: database, defaultLogger: logger)
                }
                
                let future = RedisConnection.make(
                    configuration: configuration
                    , boundEventLoop: eventLoop
                )
                
                future.whenSuccess({ redisConnection in
                    self.logger.info("init redis connection success, connection id: \(redisConnection.id)")
                    continuation.resume(returning: redisConnection)
                })
                future.whenFailure({ error in
                    self.logger.info("init redis connection error: \(error)")
                    continuation.resume(throwing: error)
                })
            } catch {
                self.logger.info("init redis connection error: \(error)")
                continuation.resume(throwing: error)
            }
        }
    }
    
    public func initPool(host:String, port:Int, username:String?, pass:String, database:Int) throws -> RedisConnectionPool {
        let eventLoop = eventLoopGroup.next()

        let addresses = try [SocketAddress.makeAddressResolvingHost(host, port: port)]
        
        let _username = username?.isEmpty ?? false ? nil : username
        let _password = pass.isEmpty ? nil : pass
        
        
        let config: RedisConnectionPool.PoolConnectionConfiguration = .init(
            initialDatabase: database
            , username: _username
            , password: _password
            , defaultLogger: self.logger, tcpClient: initClientBootstrap(eventLoop))
        
        let pool = RedisConnectionPool(
            configuration: .init(
                initialServerConnectionAddresses: addresses
                , connectionCountBehavior: .elastic(maximumConnectionCount: 2, minimumConnectionCount: 1)
                , connectionConfiguration: config
                , retryStrategy: .exponentialBackoff(initialDelay: .milliseconds(100), backoffFactor: 2, timeout: .seconds(3))
                , poolDefaultLogger: self.logger
            )
            , boundEventLoop: eventLoop
        )
        
        pool.activate()
//        _keepalive()
        self.logger.info("init redis connection pool complete...")
        return pool
    }
    
    public func initClientBootstrap(_ group: EventLoop) -> ClientBootstrap {
        let bootstrap: ClientBootstrap = ClientBootstrap(group: group)
//            .connectTimeout(timeout)
            .channelOption(
                ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR),
                value: 1
            )
            .channelInitializer {
                $0.pipeline.addRedisProHandlers()
            }
        
        return bootstrap
    }
    
}



extension ChannelPipeline {
    /// Adds the baseline channel handlers needed to support sending and receiving messages in Redis Serialization Protocol (RESP) format to the pipeline.
    ///
    /// For implementation details, see ``RedisMessageEncoder``, ``RedisByteDecoder``, and ``RedisCommandHandler``.
    ///
    /// # Pipeline chart
    ///                                                 RedisClient.send
    ///                                                         |
    ///                                                         v
    ///     +-------------------------------------------------------------------+
    ///     |                           ChannelPipeline         |               |
    ///     |                                TAIL               |               |
    ///     |    +---------------------------------------------------------+    |
    ///     |    |                  RedisCommandHandler                    |    |
    ///     |    +---------------------------------------------------------+    |
    ///     |               ^                                   |               |
    ///     |               |                                   v               |
    ///     |    +---------------------+            +----------------------+    |
    ///     |    |  RedisByteDecoder   |            |  RedisMessageEncoder |    |
    ///     |    +---------------------+            +----------------------+    |
    ///     |               |                                   |               |
    ///     |               |              HEAD                 |               |
    ///     +-------------------------------------------------------------------+
    ///                     ^                                   |
    ///                     |                                   v
    ///             +-----------------+                +------------------+
    ///             | [ Socket.read ] |                | [ Socket.write ] |
    ///             +-----------------+                +------------------+
    /// - Returns: A `NIO.EventLoopFuture` that resolves after all handlers have been added to the pipeline.
    public func addRedisProHandlers() -> EventLoopFuture<Void> {
        let _: TimeAmount = .milliseconds(1000)
        
        let handlers: [(ChannelHandler, name: String)] = [
//            (IdleStateHandler(readTimeout: timeout, writeTimeout: timeout, allTimeout: timeout), "RediPro.IdleStateHandler"),
            (MessageToByteHandler(RedisMessageEncoder()), "RediStack.OutgoingHandler"),
            (ByteToMessageHandler(RedisByteDecoder()), "RediStack.IncomingHandler"),
            (RedisCommandHandler(), "RediStack.CommandHandler")
        ]
        return .andAllSucceed(
            handlers.map { self.addHandler($0, name: $1) },
            on: self.eventLoop
        )
    }
}
