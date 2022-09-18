//
//  RedisClient.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/13.
//

import Foundation
import NIO
import RediStack
import Logging
import NIOSSH
import Swift
import ComposableArchitecture

class Cons {
    static let EMPTY_STRING = ""
}

class RediStackClient {
    let logger = Logger(label: "redis-client")
    
    var redisModel:RedisModel
    
    // conn
    private let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 2)
    var connection:RedisConnection?
    var connPool:RedisConnectionPool?
    
    var keepaliveTask: RepeatedTask?
    
    // ssh
    var sshChannel:Channel?
    var sshLocalChannel:Channel?
    var sshServer:PortForwardingServer?
    
    // 递归查询每页大小
    let dataScanCount:Int = 2000
    var dataCountScanCount:Int = 4000
    var recursionSize:Int = 2000
    var recursionCountSize:Int = 5000
    
    var viewStore:ViewStore<GlobalState, GlobalAction>?
    
    init(_ redisModel:RedisModel) {
        self.redisModel = redisModel
    }
    
    func setGlobalStore(_ globalStore: ViewStore<GlobalState, GlobalAction>?) {
        self.viewStore = globalStore
    }
    
    func loading(_ bool: Bool) {
        DispatchQueue.main.async {
            if bool {
                self.viewStore?.send(.show)
            } else {
                self.viewStore?.send(.hide)
            }
        }
    }
    
    func begin() -> Void {
        loading(true)
    }
    
    func complete<T:Any, R:Any>(_ completion:Swift.Result<T, Error>, continuation:CheckedContinuation<R, Error>) -> Void {
        if case .failure(let error) = completion {
            continuation.resume(throwing: error)
        }
  
        loading(false)
    }
    
    func complete() -> Void {
        loading(false)
    }
    
    func handleError(_ error: Error) {
        logger.info("system error \(error)")
        loading(false)
        Messages.show(error)
    }
    
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
    
    func assertExist(_ key:String) async throws {
        let exist = await exist(key)
        if !exist {
            throw BizError("key: \(key) is not exist!")
        }
    }
    
    // MARK: - Common function
    /**
    公共底层请求redis 数据方法, 不处理任何异常, 使用者需要自己行处理异常信息
     */
    func _send<R>(_ command: RedisCommand<R>) async throws -> R {
        let conn = try await getConn()
        
        return try await withCheckedThrowingContinuation { continuation in
            conn.send(command, eventLoop: nil, logger: self.logger)
                .whenComplete({completion in
                    if case .success(let r) = completion {
                        self.logger.info("string operator, setex complete")
                        continuation.resume(returning: r)
                    }
                    else if case .failure(let error) = completion {
                        continuation.resume(throwing: error)
                    }
                })
        }
    }
    
    func send<R>(_ command: RedisCommand<R>, _ defaultValue: R) async -> R {
        self.logger.info("send redis command, command: \(command)")
        begin()
        defer {
            complete()
        }
        
        do {
            return try await _send(command)
        } catch {
            handleError(error)
        }
        return defaultValue
    }
    
    func send<R>(_ command: RedisCommand<R>) async -> R? {
        self.logger.info("send redis command, command: \(command)")
        begin()
        defer {
            complete()
        }
        
        do {
            return try await _send(command)
        } catch {
            handleError(error)
        }
        return nil
    }
    
    func ttlSecond(_ lifetime: RedisKey.Lifetime) -> Int {
        switch lifetime {
        case .keyDoesNotExist:
            return -2
        case .limited(let duration):
            return Int(duration.timeAmount.nanoseconds / 1000000000)
        default:
            return -1
        }
    }
    
    func getConn() async throws -> RedisClient {
        return try await getConnPool()

//        if self.connection != nil && self.connection!.isConnected {
//            return self.connection!
//        } else {
//            self.logger.info("get redis connection, but connection is not available...")
//            self.close()
//        }
//
//        if self.redisModel.connectionType == RedisConnectionTypeEnum.SSH.rawValue {
//            self.connection = try await initSSHConn()
//        } else {
//            self.connection = try await initConn(host: self.redisModel.host, port: self.redisModel.port, pass: self.redisModel.password, database: self.redisModel.database)
//        }
//
//        return self.connection!
    }
    
    func getConnPool() async throws -> RedisClient {
        if self.connPool != nil {
            return self.connPool!
        } else {
            self.logger.info("get redis connection, but connection is not available...")
            self.close()
        }
        
        if self.redisModel.connectionType == RedisConnectionTypeEnum.SSH.rawValue {
            self.connection = try await initSSHConn()
        } else {
            self.connPool = try initPool(host: self.redisModel.host, port: self.redisModel.port, pass: self.redisModel.password, database: self.redisModel.database)
        }
        
        return self.connPool!
    }
    
    func initConn(host:String, port:Int, pass:String, database:Int) async throws -> RedisConnection {
        

        logger.info("init new redis connection, host: \(host), port: \(port), pass: \(pass), database: \(database)")
        return try await withCheckedThrowingContinuation { continuation in
            do {
                let eventLoop = MultiThreadedEventLoopGroup(numberOfThreads: 4).next()
                var configuration: RedisConnection.Configuration
                if (pass.isEmpty) {
                    configuration = try RedisConnection.Configuration(hostname: host, port: port, initialDatabase: database, defaultLogger: logger)
                } else {
                    configuration = try RedisConnection.Configuration(hostname: host, port: port, password: pass, initialDatabase: database, defaultLogger: logger)
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
    
    public func initPool(host:String, port:Int, pass:String, database:Int) throws -> RedisConnectionPool {
        let eventLoop = eventLoopGroup.next()

        let addresses = try [SocketAddress.makeAddressResolvingHost(host, port: port)]
        
        let password = pass.isEmpty ? nil : pass
        
        let config: RedisConnectionPool.PoolConnectionConfiguration = .init(
            initialDatabase: database
            , password: password
            , defaultLogger: self.logger, tcpClient: nil)
        
        let pool = RedisConnectionPool(
            configuration: .init(
                initialServerConnectionAddresses: addresses
                , connectionCountBehavior: .elastic(maximumConnectionCount: 3, minimumConnectionCount: 2)
                , connectionConfiguration: config
                , retryStrategy: .exponentialBackoff(initialDelay: .milliseconds(100), timeout: .seconds(5))
                , poolDefaultLogger: self.logger
            )
            , boundEventLoop: eventLoop)
        
        pool.activate()
        
//        _keepalive()
        self.logger.info("init redis connection pool complete...")
        return pool
    }
    
    private func _keepalive() {
        let eventLoop = eventLoopGroup.next()
        self.keepaliveTask = eventLoop.scheduleRepeatedAsyncTask(initialDelay: .seconds(10), delay: .seconds(5)) {_ in
            self.logger.info("keep alive connection...")
            self.connPool?.leaseConnection() { conn in
                return conn.send(.echo("redis-pro heartbeat"))
            }.whenComplete({completion in
                if case .success(let r) = completion {
                    self.logger.info("keepalive heartbeat echo: \(r)")
                }
                else if case .failure(let error) = completion {
                    self.logger.info("keepalive heartbeat error: \(error)")
                }
            })
            
            return eventLoop.makeSucceededVoidFuture()
        }
    }
    
    // close
    func close() -> Void {
        self.connection?.close().whenComplete({completion in
                self.connection = nil
                self.logger.info("redis connection close")
            })
        self.connPool?.close()
        self.connPool = nil
        self.logger.info("redis connection pool close")
        
        self.closeSSH()
        
        self.keepaliveTask?.cancel()
    }
    
    deinit {
        do {
            logger.info("gracefully shutdown event loop group start...")
            try self.eventLoopGroup.syncShutdownGracefully()
        } catch {
            logger.info("gracefully shutdown event loop group error: \(error)")
        }
    }
}



// MARK: RESPValue Conversion
extension RESPValue {
    @usableFromInline
    func map<T: RESPValueConvertible>(to type: T.Type = T.self) throws -> T {
        guard let value = T(fromRESP: self) else { throw RedisClientError.failedRESPConversion(to: type) }
        return value
    }
}
