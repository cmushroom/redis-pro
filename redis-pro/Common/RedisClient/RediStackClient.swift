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
import ComposableArchitecture
import Cocoa

class RediStackClient {
    let logger = Logger(label: "redis-client")
    var redisModel:RedisModel
    
    // conn
    let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 2)
    var connection:RedisConnection?
    var connPool:RedisConnectionPool?
    
    var keepaliveTask: RepeatedTask?
    
    // ssh
    var sshChannel:Channel?
    var sshLocalChannel:Channel?
    var sshServer:PortForwardingServer?
    
    // 递归查询每页大小
    let dataScanCount:Int = 2000
    var dataCountScanCount:Int = 2000
    var recursionSize:Int = 2000
    var recursionCountSize:Int = 5000
    
    private var observers = [NSObjectProtocol]()
    
    var appContextViewStore:ViewStore<AppContextStore.State, AppContextStore.Action>?
    var settingViewStore: ViewStoreOf<SettingsStore>?
    
    convenience init(_ redisModel:RedisModel, settingViewStore: ViewStoreOf<SettingsStore>?) {
        self.init(redisModel)
        self.settingViewStore = settingViewStore
    }
    
    init(_ redisModel:RedisModel) {
        self.redisModel = redisModel
        
        // 监听app退出
        observers.append(
            NotificationCenter.default.addObserver(forName: NSApplication.willTerminateNotification, object: nil, queue: .main) { [self] _ in
                logger.info("redis pro will exit...")
                
                shutdown()
            }
        )
    }
    
    deinit {
        observers.forEach(NotificationCenter.default.removeObserver)
    }
    
    func setAppContextStore(_ globalStore: ViewStore<AppContextStore.State, AppContextStore.Action>?) {
        self.appContextViewStore = globalStore
    }
    
    func loading(_ bool: Bool) {
        DispatchQueue.main.async {
            if bool {
                self.appContextViewStore?.send(.show)
            } else {
                self.appContextViewStore?.send(.hide)
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
    
    
    func assertExist(_ key:String) async throws {
        let exist = await exist(key)
        if !exist {
            throw BizError("key: \(key) is not exist!")
        }
    }
    
    // MARK: - Common function
    func _send<R>(_ conn: RedisClient, _ command: RedisCommand<R>) async throws -> R {
        return try await withCheckedThrowingContinuation { continuation in
            conn.send(command, eventLoop: nil, logger: self.logger)
                .whenComplete({completion in
                    if case .success(let r) = completion {
                        self.logger.info("send redis command: \(command) complete")
                        continuation.resume(returning: r)
                    }
                    else if case .failure(let error) = completion {
                        continuation.resume(throwing: error)
                    }
                })
        }
    }
    

    // 公共底层请求redis 数据方法, 不处理任何异常, 使用者需要自己行处理异常信息
    func _send<R>(_ command: RedisCommand<R>) async -> R? {
        do {
            let conn = try await getConn()
            return try await _send(conn, command)
        } catch {
            handleError(error)
        }
        
        return nil
    }
    
    // 公共底层请求redis 数据方法, 不处理任何异常, 使用者需要自己行处理异常信息
    func _send<R>(_ command: RedisCommand<R>, _ defaultValue: R) async -> R {
        return await _send(command) ?? defaultValue
    }
    
    func send<R>(_ command: RedisCommand<R>, _ defaultValue: R) async -> R {
        self.logger.info("send redis command, command: \(command)")
        begin()
        defer {
            complete()
        }
        
        return await _send(command) ?? defaultValue
    }
    
    func send<R>(_ command: RedisCommand<R>) async -> R? {
        self.logger.info("send redis command, command: \(command)")
        begin()
        defer {
            complete()
        }
        
        return await _send(command)
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
                self.logger.info("redis client- connection close")
            })
        self.connPool?.close()
        self.connPool = nil
        self.logger.info("redis client- connection pool close")
        
        self.closeSSH()
    }
    
    func shutdown() {
        do {
            close()
            
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
