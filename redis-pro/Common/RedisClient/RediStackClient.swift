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
    var connection:RedisConnection?
    
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

    // MARK: - string operator
    /**
     set value expire(seconds)
     */
    func set(_ key:String, value:String, ex:Int = -1) async -> Void {
        logger.info("set value, key:\(key), value:\(value), ex:\(ex)")
        
        let command:RedisCommand<Void> = ex == -1 ? .set(RedisKey(key), to: value) : .setex(RedisKey(key), to: value, expirationInSeconds: ex)
        
        await send(command)
    }
    
    func set(_ key:String, value:String) async -> Void {
        logger.info("set value, key:\(key), value:\(value)")
        
        await set(key, value:value, ex: -1)
    }
    
    func get(_ key:String) async -> String {
        logger.info("get value, key:\(key)")
        
        let command:RedisCommand<RESPValue?> = .get(RedisKey(key))
        let r = await send(command)
        return r??.string ?? Cons.EMPTY_STRING
    }
    
    func del(_ key:String) async -> Int {
        self.logger.info("delete key \(key)")
        
        let command:RedisCommand<Int> = .del([RedisKey(key)])
        return await send(command, 0)
    }
    
    func expire(_ key:String, seconds:Int = -1) async -> Bool {
        logger.info("set key expire key:\(key), seconds:\(seconds)")
        
        do {
            
            let maxSeconds:Int64 = INT64_MAX / (1000 * 1000 * 1000)
            try Assert.isTrue(seconds < maxSeconds, message: "过期时间最大值不能超过 \(maxSeconds) 秒")
            
            let command:RedisCommand<Bool> = seconds < 0 ?
                // PERSIST
                .init(keyword: "PERSIST", arguments: [.init(from: key)], mapValueToResult: {
                    return $0.int == 1
                }) : .expire(RedisKey(key), after: .seconds(Int64(seconds)))
            return await send(command, false)
            
        } catch {
            handleError(error)
        }
        return false
    }
    
    func exist(_ key:String) async -> Bool {
        logger.info("get key exist: \(key)")
        let command:RedisCommand<Int> = .exists(RedisKey(key))
        return await send(command) == 1
    }
    
    func ttl(_ key:String) async -> Int {
        logger.info("get ttl key: \(key)")
        let command:RedisCommand<RedisKey.Lifetime> = .ttl(RedisKey(key))
        return ttlSecond(await send(command, RedisKey.Lifetime.keyDoesNotExist))
    }
    
    func getTypes(_ keys:[String]) async -> [String:String] {
        return await withTaskGroup(of: (String, String).self) { group in
            var typeDict = [String:String]()
            
            // adding tasks to the group and fetching movies
            for key in keys {
                group.addTask {
                    let type = await self.type(key)
                    return (key, type)
                }
            }
            
            for await type in group {
                typeDict[type.0] = type.1
            }
            
            return typeDict
        }
    }
    
    private func type(_ key:String) async -> String {
        do {
            let command:RedisCommand<String> = .type(key)
            return try await _send(command)
        } catch {
            self.logger.error("get type error: \(error)")
        }
        return RedisKeyTypeEnum.NONE.rawValue
    }
    
    
    func rename(_ oldKey:String, newKey:String) async -> Bool {
        logger.info("rename key, old key:\(oldKey), new key: \(newKey)")
        
        let command:RedisCommand<Int> = .renamenx(oldKey, newKey: newKey)
        let r = await send(command, 0)
        if r == 0 {
            Messages.show("rename key error, new key: \(newKey) already exists.")
        }
        
        return r > 0
    }
    
    func getConn() async throws -> RedisClient {
        if self.connection != nil && self.connection!.isConnected {
            return self.connection!
        } else {
            self.logger.info("get redis connection, but connection is not available...")
            self.close()
        }
        
        if self.redisModel.connectionType == RedisConnectionTypeEnum.SSH.rawValue {
            self.connection = try await initSSHConn()
        } else {
            self.connection = try await initConn(host: self.redisModel.host, port: self.redisModel.port, pass: self.redisModel.password, database: self.redisModel.database)
        }
        
        return self.connection!
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
    
//    public func initPool() throws -> RedisConnectionPool {
//        let eventLoop = MultiThreadedEventLoopGroup(numberOfThreads: 4).next()
//
//        let addresses = try [SocketAddress.makeAddressResolvingHost(self.redisModel.host, port: self.redisModel.port)]
//        let pool = RedisConnectionPool(
//            configuration: .init(
//                initialServerConnectionAddresses: addresses,
//                maximumConnectionCount: .maximumActiveConnections(4),
//                connectionFactoryConfiguration: .init(connectionInitialDatabase: self.redisModel.database, connectionPassword: self.redisModel.password, connectionDefaultLogger: nil, tcpClient: nil),
//                minimumConnectionCount: 2,
//                connectionBackoffFactor: 2,
//                initialConnectionBackoffDelay: .milliseconds(100),
//                connectionRetryTimeout: .seconds(60)
//                ),
//            boundEventLoop: eventLoop
//        )
//        pool.activate()
//
//        self.logger.info("init redis connection pool complete...")
//        return pool
//    }
    
    func close() -> Void {
        guard let conn = self.connection else {
            logger.info("close redis connection, connection is nil, over...")
            return
        }
            
        conn.close().whenComplete({completion in
                self.connection = nil
                self.logger.info("redis connection close success")
            })
        
        self.closeSSH()
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
