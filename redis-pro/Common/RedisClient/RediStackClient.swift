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
    
    init(redisModel:RedisModel) {
        self.redisModel = redisModel
    }
    
    func begin() -> Void {
        LoadingUtil.show()
    }
    
    func complete<T:Any, R:Any>(_ completion:Swift.Result<T, Error>, continuation:CheckedContinuation<R, Error>) -> Void {
        if case .failure(let error) = completion {
            continuation.resume(throwing: error)
        }
  
        LoadingUtil.hide()
    }
    
    func complete() -> Void {
        LoadingUtil.hide()
    }
    
    func handleError(_ error: Error) {
        logger.info("get an error \(error)")
        LoadingUtil.hide()
        Messages.show(error)
    }
    
    func handleConnectionError(_ error:Error) {
        logger.info("get connection error \(error)")
    }
    
    /*
     * 初始化redis 连接
     */
    func initConnection() async -> Bool {
        begin()
        let conn = try? await getConn()
  
        LoadingUtil.hide()
        return conn != nil
    }
    
    func assertExist(_ key:String) async throws {
        let exist = await exist(key)
        if !exist {
            throw BizError("key: \(key) is not exist!")
        }
    }
    
    // string operator
    func set(_ key:String, value:String, ex:Int?) async -> Void {
        logger.info("set value, key:\(key), value:\(value), ex:\(ex ?? -1)")
        begin()
        do {
            let conn = try await getConn()
            
            return try await withCheckedThrowingContinuation { continuation in
                if (ex == nil || ex! == -1) {
                    conn.set(RedisKey(key), to: value)
                        .whenComplete({completion in
                            if case .success(_) = completion {
                                continuation.resume()
                            }
                
                            self.complete(completion, continuation: continuation)
                        })
                } else {
                    conn.setex(RedisKey(key), to: value, expirationInSeconds: ex!)
                        .whenComplete({completion in
                            if case .success(_) = completion {
                                continuation.resume()
                            }
                            
                            self.complete(completion, continuation: continuation)
                        })
                }
            }
        } catch {
            handleError(error)
        }
        
    }
    
    func set(_ key:String, value:String) async -> Void {
        logger.info("set value, key:\(key), value:\(value)")
        
        await set(key, value:value, ex: -1)
        
    }
    
    func get(_ key:String) async -> String {
        logger.info("get value, key:\(key)")
        begin()
        do {
            let conn = try await getConn()
            
            return try await withCheckedThrowingContinuation { continuation in
                
                conn.get(RedisKey(key))
                    .whenComplete({completion in
                        if case .success(let r) = completion {
                            self.logger.info("get value key: \(key) complete, r: \(r)")
                            if r.isNull {
                                continuation.resume(throwing: BizError(message: "Key `\(key)` is not exist!"))
                            } else {
                                continuation.resume(returning: r.string!)
                            }
                        }
                        
                        self.complete(completion, continuation: continuation)
                    })
                
            }
        } catch {
            handleError(error)
        }
        return Cons.EMPTY_STRING
    }
    
    func del(_ key:String) async -> Int {
        self.logger.info("delete key \(key)")
        begin()
 
        do {
            let conn = try await getConn()
            
            return try await withCheckedThrowingContinuation { continuation in
                
                conn.delete(RedisKey(key))
                    .whenComplete({completion in
                        if case .success(let r) = completion {
                            self.logger.info("delete redis key \(key) complete, r: \(r)")
                            continuation.resume(returning: r)
                        }
                        
                        self.complete(completion, continuation: continuation)
                    })
                
            }
        } catch {
            handleError(error)
        }
        return 0
    }
    
    func expire(_ key:String, seconds:Int) async -> Bool {
        logger.info("set key expire key:\(key), seconds:\(seconds)")
        
        begin()
        do {
            
            let maxSeconds:Int64 = INT64_MAX / (1000 * 1000 * 1000)
            try Assert.isTrue(seconds < maxSeconds, message: "过期时间最大值不能超过 \(maxSeconds) 秒")
            
            let conn = try await getConn()
            
            return try await withCheckedThrowingContinuation { continuation in
                
                if seconds < 0 {
                    conn.send(command: "PERSIST", with: [RESPValue(from: key)]).whenComplete({completion in
                        if case .success(let r) = completion {
                            self.logger.info("clear key expire time \(key) complete, r: \(r)")
                            continuation.resume(returning: true)
                        }
                        self.complete(completion, continuation: continuation)
                    })
                } else {
                    conn.expire(RedisKey(key), after: TimeAmount.seconds(Int64(seconds))).whenComplete({completion in
                        if case .success(let r) = completion {
                            self.logger.info("set key expire time \(key) complete, r: \(r)")
                            continuation.resume(returning: true)
                        }
                        
                        self.complete(completion, continuation: continuation)
                    })
                }
                
            }
        } catch {
            handleError(error)
        }
        return false
    }
    
    func exist(_ key:String) async -> Bool {
        logger.info("get key exist: \(key)")
        do {
            let conn = try await getConn()
            
            return try await withCheckedThrowingContinuation { continuation in
                
                conn.exists(RedisKey(key))
                    .whenComplete({completion in
                        if case .success(let r) = completion {
                            self.logger.info("query redis key exist, key: \(key), r:\(r)")
                            continuation.resume(returning: r > 0)
                        }
                        else if case .failure(let error) = completion {
                            self.logger.error("redis get key exist error \(error)")
                            continuation.resume(returning: false)
                        }
                    })
                
            }
        } catch {
            self.logger.error("redis get key exist error \(error)")
        }
        return false
    }
    
    func ttl(_ key:String) async -> Int {
        logger.info("get ttl key: \(key)")
        begin()
        do {
            let conn = try await getConn()
            
            return try await withCheckedThrowingContinuation { continuation in
                
                conn.ttl(RedisKey(key))
                    .whenComplete({completion in
                        if case .success(let r) = completion {
                            self.logger.info("query redis key ttl, key: \(key), r:\(r)")
                            var ttl = -1
                            if r == RedisKey.Lifetime.keyDoesNotExist {
                                ttl = -2
//                                continuation.resume(throwing: BizError(message: "Key `\(key)` is not exist!"))
//                                return
                            } else if r == RedisKey.Lifetime.unlimited {
                               // ignore
                            } else {
                                ttl = Int(r.timeAmount!.nanoseconds / 1000000000)
                            }
                            continuation.resume(returning: ttl)
                        }
                        
                        self.complete(completion, continuation: continuation)
                    })
                
            }
        } catch {
            handleError(error)
        }
        return -1
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
            let conn = try await getConn()
            
            return try await withCheckedThrowingContinuation { continuation in
                
                conn.send(command: "type", with: [RESPValue.init(from: key)])
                    .whenComplete({completion in
                        if case .success(let r) = completion {
                            continuation.resume(returning: r.string!)
                        } else if case .failure(let error) = completion {
                            self.logger.error("get key type error: \(error)")
                            continuation.resume(returning: RedisKeyTypeEnum.NONE.rawValue)
                        }
                    })
                
            }
        } catch {
            self.logger.error("get key type error: \(error)")
        }
        
        return RedisKeyTypeEnum.NONE.rawValue
    }
    
    func rename(_ oldKey:String, newKey:String) async -> Bool {
        logger.info("rename key, old key:\(oldKey), new key: \(newKey)")
        begin()
 
        do {
            let conn = try await getConn()
            
            return try await withCheckedThrowingContinuation { continuation in
                
                conn.send(command: "RENAME", with: [RESPValue(from: oldKey), RESPValue(from: newKey)])
                    .whenComplete({completion in
                        if case .success(let r) = completion {
                            self.logger.info("rename redis key, old key \(oldKey), new key: \(newKey) complete, r: \(r)")
                            continuation.resume(returning: r.string == "OK")
                        }
                        
                        self.complete(completion, continuation: continuation)
                    })
                
            }
        } catch {
            handleError(error)
        }
        return false
    }
    
    func getConn() async throws -> RedisConnection {
        if self.connection != nil && self.connection!.isConnected {
            return self.connection!
        } else {
            self.logger.info("get redis connection, but connection is not available...")
            self.close()
        }
        
        
        if self.redisModel.connectionType == RedisConnectionTypeEnum.SSH.rawValue {
            return try await getSSHConn()
        }
        
        
        return try await withUnsafeThrowingContinuation { continuation in
            self.logger.info("start get new redis connection...")
            
            do {
                let eventLoop = MultiThreadedEventLoopGroup(numberOfThreads: 1).next()
                var configuration: RedisConnection.Configuration
                if (self.redisModel.password.isEmpty) {
                    configuration = try RedisConnection.Configuration(hostname: self.redisModel.host, port: self.redisModel.port, initialDatabase: self.redisModel.database, defaultLogger: logger)
                } else {
                    configuration = try RedisConnection.Configuration(hostname: self.redisModel.host, port: self.redisModel.port, password: self.redisModel.password, initialDatabase: self.redisModel.database, defaultLogger: logger)
                }
                
                let future = RedisConnection.make(
                    configuration: configuration
                    , boundEventLoop: eventLoop
                )
                
                future.whenSuccess({ redisConnection in
                    self.connection = redisConnection
                    self.logger.info("get new redis connection success, connection id: \(redisConnection.id)")
                    continuation.resume(returning: self.connection!)
                })
                future.whenFailure({ error in
                    self.logger.info("get new redis connection error: \(error)")
                    self.handleConnectionError(error)
                    continuation.resume(throwing: error)
                })
            } catch {
                self.handleConnectionError(error)
                continuation.resume(throwing: error)
            }
        }
    }
    
    func close() -> Void {
        if connection == nil {
            logger.info("close redis connection, connection is nil, over...")
            return
        }
        
        connection!.close().whenComplete({completion in
            self.connection = nil
            self.logger.info("redis connection close success")
        })
        
        self.closeSSH()
    }
}
