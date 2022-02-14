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

class Cons {
    static let EMPTY_STRING = ""
}

class RediStackClient {
    let logger = Logger(label: "redis-client")
    
    var redisModel:RedisModel
    var connection:RedisConnection?
    var globalContext:GlobalContext?
    
    // ssh
    var sshChannel:Channel?
    var sshLocalChannel:Channel?
    var sshServer:PortForwardingServer?
    
    // 递归查询每页大小
    private var recursionSize:Int = 2000
    private var recursionCountSize:Int = 5000
    
    init(redisModel:RedisModel) {
        self.redisModel = redisModel
    }
    
    func setUp(_ globalContext:GlobalContext?) -> Void {
        self.globalContext = globalContext
    }
    
    func begin() -> Void {
        DispatchQueue.main.async {
            self.globalContext?.loading = true
        }
    }
    
    func complete<T:Any, R:Any>(_ completion:Swift.Result<T, Error>, continuation:CheckedContinuation<R, Error>) -> Void {
        if case .failure(let error) = completion {
            continuation.resume(throwing: error)
        }
        
        DispatchQueue.main.async {
            self.globalContext?.loading = false
        }
    }
    
    func complete() -> Void {
        DispatchQueue.main.async {
            self.globalContext?.loading = false
        }
    }
    
    func handleError(_ error: Error) {
        logger.info("get an error \(error)")
        DispatchQueue.main.async {
            self.globalContext?.showError(error)
            self.globalContext?.loading = false
        }
    }
    
    func handleConnectionError(_ error:Error) {
        logger.info("get connection error \(error)")
//        DispatchQueue.main.async {
//            self.globalContext?.showError(error)
//            self.globalContext?.loading = false
//        }
    }
    
    /*
     * 初始化redis 连接
     */
    func initConnection() async -> Bool {
        begin()
        let conn = try? await getConn()
        
        DispatchQueue.main.async {
            self.globalContext?.loading = false
        }
        return conn != nil
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
    
    private func exist(_ key:String) async -> Bool {
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
                                continuation.resume(throwing: BizError(message: "Key `\(key)` is not exist!"))
                                return
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
    
    private func getTypes(_ keys:[String]) async -> [String:String] {
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
    
//    func afterPromise<T:CatchMixin>(_ promise:T) -> Void {
//        promise
//            .catch({error in
//                self.globalContext?.showError(error)
//            })
//                    .finally {
//                self.globalContext?.loading = false
//            }
//    }
}

// key
extension RediStackClient {
    
    
    private func keyScan(cursor:Int, keywords:String?, count:Int? = 1) async throws -> (cursor:Int, keys:[String]) {
        logger.debug("redis keys scan, cursor: \(cursor), keywords: \(String(describing: keywords)), count:\(String(describing: count))")
        
        
        let conn = try await getConn()
        
        return try await withCheckedThrowingContinuation { continuation in
            conn.scan(startingFrom: cursor, matching: keywords, count: count)
                .whenComplete({completion in
                    if case .success(let r) = completion {
                        continuation.resume(returning: r)
                    }
                    else if case .failure(let error) = completion {
                        self.logger.error("redis keys scan error \(error)")
                        continuation.resume(throwing: error)
                    }
                })
        }
    }
    
    // 递归取出包含分页的数据
    private func recursionScan(_ keywords:String?, cursor:Int, maxCount:Int, keys:[String]) async throws -> (cursor:Int, keys:[String]) {
        if keys.count >= maxCount {
            self.logger.info("recursion scan get keys enough, max count: \(maxCount), current count: \(keys.count)")
            return (cursor, keys)
        } else {
            let res = try await keyScan(cursor: cursor, keywords: keywords, count: recursionSize)
            let newKeys = keys + res.keys
            
            if res.cursor == 0 {
                self.logger.info("recursion scan reach end, max count: \(maxCount), current count: \(keys.count)")
                
                return (res.cursor, newKeys)
            }
            
            self.logger.info("recursion scan get more keys, current count: \(newKeys.count)")
            return try await self.recursionScan(keywords, cursor: res.cursor, maxCount: maxCount, keys: newKeys)
        }
    }
    
    private func scanTotal(_ keywords:String?, cursor:Int, total:Int) async throws -> Int {
        let res = try await keyScan(cursor: cursor, keywords: keywords, count: recursionCountSize)
        let newTotal:Int = total + res.keys.count
        if res.cursor == 0 {
            self.logger.info("recursion scan total reach end, total: \(newTotal)")
            
            return newTotal
        }
        
        self.logger.info("recursion scan total get more, current total: \(newTotal)")
        return try await self.scanTotal(keywords, cursor: res.cursor, total: newTotal)
    }
    
    
    private func isMatchAll(_ keywords:String?) -> Bool {
        guard let keywords = keywords else {
            return true
        }
        return keywords.isEmpty || keywords == "*" || keywords == "**"
    }
    
    private func isScan(_ keywords:String) -> Bool {
        return keywords.isEmpty || keywords.contains("*") || keywords.contains("?")
    }
    
    private func recursionScanTotal(_ keywords:String?) async throws -> Int {
        if isMatchAll(keywords ?? "") {
            logger.info("keywords is match all, use dbsize...")
            return await dbsize()
        }
        
        let cursor:Int = 0
        let total:Int = 0
        
        return try await scanTotal(keywords, cursor: cursor, total: total)
    }
    
    func pageKeys(_ page:Page) async -> [RedisKeyModel] {
        begin()
        
        let stopwatch = Stopwatch.createStarted()
        
        logger.info("redis keys page scan, page: \(page)")
        
        let isScan = isScan(page.keywords)
        let match = page.keywords.isEmpty ? nil : page.keywords
        
        let keys:[String] = [String]()
        let cursor:Int = 0
        
        defer {
            self.logger.info("keys scan complete, spend: \(stopwatch.elapsedMillis()) ms")
            complete()
        }
        
        do {
            // 带有占位符的情况，使用
            if isScan {
                async let totalAsync = recursionScanTotal(match)
                
                async let res = self.recursionScan(match, cursor: cursor, maxCount: page.size, keys: keys)
                
                let total = try await totalAsync
                let keys = try await res.keys
                
                let start = (page.current - 1) * page.size
                
                if keys.count <= start {
                    return []
                }
                
                let end = min(start + page.size - 1, keys.count)
                let pageData:[String] = Array(keys[start..<end])
                
                
                DispatchQueue.main.async {
                    page.total = total
                }
                return await self.toRedisKeyModels(pageData)
            } else {
                let exist = await self.exist(page.keywords)
                if exist {
                    page.total = 1
                    return await self.toRedisKeyModels([page.keywords])
                } else {
                    page.total = 0
                    return []
                }
            }
            
        } catch {
            self.logger.error("get key type error: \(error)")
            self.handleError(error)
        }

        return []
    }
    
    private func toRedisKeyModels(_ keys:[String]) async -> [RedisKeyModel] {
        if keys.isEmpty {
            return []
        }
        
        var redisKeyModels = [RedisKeyModel]()
        
        let typeDict = await getTypes(keys)
        
        for key in keys {
            redisKeyModels.append(RedisKeyModel(key, type: typeDict[key] ?? RedisKeyTypeEnum.NONE.rawValue))
        }
        
        return redisKeyModels
    }
    
}

// hash
extension RediStackClient {
    
    // hash operator
    
    func pageHash(_ key:String, page:ScanModel) async -> [RedisHashEntryModel] {
        logger.info("redis hash field page scan, key: \(key), page: \(page)")
        
        begin()
        defer {
            complete()
        }
        do {
            let match = page.keywords.isEmpty ? nil : page.keywords
            
            let cursor:Int = page.cursor
            let fields:[(String, String?)] = []
            
            let res = try await recursionHScan(key, keywords: match, cursor: cursor, maxCount: page.size, fields: fields)
            
            page.cursor = res.0
            
            let pageData:[(String, String?)] = res.1
            let r:[RedisHashEntryModel] = pageData.sorted(by: {$0.0 > $1.0}).map({
                RedisHashEntryModel(field: $0.0, value: $0.1)
            })
            
            let total = try await recursionHScanTotal(key, keywords: match)
            page.total = total
            
            return r
        } catch {
            handleError(error)
        }
        return []
    }
    
    func hset(_ key:String, field:String, value:String) async -> Bool {
        logger.info("redis hash hset key:\(key), field:\(field), value:\(value)")
        begin()
 
        do {
            let conn = try await getConn()
            
            return try await withCheckedThrowingContinuation { continuation in
                
                conn.hset(field, to: value, in: RedisKey(key))
                    .whenComplete({completion in
                        if case .success(let r) = completion {
                            self.logger.info("hset success, key:\(key), field:\(field), value:\(value), r:\(r)")
                            continuation.resume(returning: true)
                        }
                        
                        self.complete(completion, continuation: continuation)
                    })
                
            }
        } catch {
            handleError(error)
        }
        return false
    }
    
    func hdel(_ key:String, field:String) async -> Int {
        logger.info("redis hash hdel key:\(key), field:\(field)")
        begin()
 
        do {
            let conn = try await getConn()
            
            return try await withCheckedThrowingContinuation { continuation in
                
                conn.hdel(field, from: RedisKey(key))
                    .whenComplete({completion in
                        if case .success(let r) = completion {
                            self.logger.info("hdel success, key:\(key), field:\(field)")
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
    
    // 递归取出包含分页的数据
    private func recursionHScan(_ key:String, keywords:String?, cursor:Int, maxCount:Int, fields:[(String, String?)]) async throws -> (Int, [(String, String?)]) {
        if fields.count >= maxCount {
            self.logger.info("recursion scan get keys enough, max count: \(maxCount), current count: \(fields.count)")
            return (cursor, fields)
        } else {
            let res = try await hscan(key, keywords: keywords, cursor: cursor, count: maxCount)
            
            let newFields:[(String, String?)] = fields + res.1.map{$0}
            
            if res.0 == 0 {
                self.logger.info("recursion hscan reach end, max count: \(maxCount), current count: \(newFields.count)")
                
                return (res.0, newFields)
            }
            
            self.logger.info("recursion hscan get more keys, current count: \(newFields.count)")
            return try await recursionHScan(key, keywords: keywords, cursor: res.0, maxCount: maxCount, fields: newFields)
        }
    }
    
    private func hscanTotal(_ key:String, keywords:String?, cursor:Int, total:Int) async throws -> Int {
        let res = try await hscan(key, keywords: keywords, cursor: cursor, count: 1000)
        let newTotal:Int = total + res.1.count
        if res.0 == 0 {
            self.logger.info("recursion scan total reach end, total: \(newTotal)")
            
            return newTotal
        }
        
        self.logger.info("recursion scan total get more, current total: \(newTotal)")
        return try await hscanTotal(key, keywords: keywords, cursor: res.0, total: newTotal)
    }
    
    private func recursionHScanTotal(_ key:String, keywords:String?) async throws -> Int {
        if isMatchAll(keywords) {
            logger.info("hscan total key: \(key), keywords is match all, use hlen...")
            return try await hlen(key)
        }
        
        let cursor:Int = 0
        let total:Int = 0
        
        return try await hscanTotal(key, keywords: keywords, cursor: cursor, total: total)
    }
    
    private func hlen(_ key:String) async throws -> Int {
        let conn = try await getConn()
        return try await withCheckedThrowingContinuation { continuation in
            
            conn.hlen(of: RedisKey(key))
                .whenComplete({completion in
                    if case .success(let r) = completion {
                        continuation.resume(returning: r)
                    }
                    else if case .failure(let error) = completion {
                        self.logger.error("redis hash hlen error \(error)")
                        continuation.resume(throwing: error)
                    }
                })
            
        }
    }
    
    private func hscan(_ key:String, keywords:String?, cursor:Int, count:Int? = 1) async throws -> (Int, [String: String?]) {
        logger.debug("redis hash scan, key: \(key) cursor: \(cursor), keywords: \(String(describing: keywords)), count:\(String(describing: count))")
        
        let conn = try await getConn()
        return try await withCheckedThrowingContinuation { continuation in
            
            conn.hscan(RedisKey(key), startingFrom: cursor, matching: keywords, count: count, valueType: String.self)
                .whenComplete({completion in
                    if case .success(let r) = completion {
                        continuation.resume(returning: r)
                    }
                    else if case .failure(let error) = completion {
                        self.logger.error("redis hash scan error \(error)")
                        continuation.resume(throwing: error)
                    }
                })
            
        }
    }
    
    func hget(_ key:String, field:String) async -> String {
        logger.info("get hash field value, key:\(key), field: \(field)")
        begin()
 
        do {
            let conn = try await getConn()
            
            return try await withCheckedThrowingContinuation { continuation in
                
                conn.hget(field, from: RedisKey(key))
                    .whenComplete({completion in
                        if case .success(let r) = completion {
                            self.logger.info("hget value key: \(key), field: \(field) complete, r: \(r)")
                            continuation.resume(returning: r.string!)
                        }
                        
                        self.complete(completion, continuation: continuation)
                    })
                
            }
        } catch {
            handleError(error)
        }
        return Cons.EMPTY_STRING
    }
}

// zset
extension RediStackClient {
    
    // zset operator
    
    func pageZSet(_ key:String, page: Page) async -> [RedisZSetItemModel] {
        logger.info("redis zset scan page, key: \(key), page: \(page)")
        
        begin()
        defer {
            complete()
        }
        do {
            let match = page.keywords.isEmpty ? nil : page.keywords
            
            let cursor:Int = 0
            let items:[(String, Double)?] = []
            let maxCount = page.current * page.size
            
            let res = try await recursionZScan(key, keywords: match, cursor: cursor, maxCount: maxCount, items: items)
            let start = (page.current - 1) * page.size
            
            if res.1.count <= start {
                return []
            }
            
            let end = min(start + page.size - 1, res.1.count)
            let pageData:[RedisZSetItemModel] = Array(res.1[start..<end]).map {
                RedisZSetItemModel(value: $0?.0 ?? "", score: "\($0?.1 ?? 0)")
            }
            
            let total = try await recursionZScanTotal(key, keywords: match)
            page.total = total
            
            return pageData
        } catch {
            self.handleError(error)
        }
        return []

    }
    
    // 递归取出包含分页的数据
    private func recursionZScan(_ key:String, keywords:String?, cursor:Int, maxCount:Int, items:[(String, Double)?]) async throws -> (Int, [(String, Double)?]) {
        if items.count >= maxCount {
            self.logger.info("recursion zscan get items enough, max count: \(maxCount), current count: \(items.count)")
            return (cursor, items)
        } else {
            let res = try await zscanAsync(key, keywords: keywords, cursor: cursor, count: recursionSize)
            let newItems:[(String, Double)?] = items + res.1
            
            if res.0 == 0 {
                self.logger.info("recursion zscan reach end, max count: \(maxCount), current count: \(newItems.count)")
                
                return (res.0, newItems)
            }
            
            self.logger.info("recursion zscan get more keys, current count: \(newItems.count)")
            return try await recursionZScan(key, keywords: keywords, cursor: res.0, maxCount: maxCount, items: newItems)
        }
    }
    
    private func zscanTotal(_ key:String, keywords:String?, cursor:Int, total:Int) async throws -> Int {
        let res = try await zscanAsync(key, keywords: keywords, cursor: cursor, count: 1000)
        let newTotal:Int = total + res.1.count
        
        if res.0 == 0 {
            self.logger.info("recursion zscan total reach end, total: \(newTotal)")
            return newTotal
        }
        
        self.logger.info("recursion zscan total get more, current total: \(newTotal)")
        return try await zscanTotal(key, keywords: keywords, cursor: res.0, total: newTotal)
    }
    
    private func recursionZScanTotal(_ key:String, keywords:String?) async throws -> Int {
        if isMatchAll(keywords) {
            logger.info("keywords is match all, use scard...")
            return try await zcard(key)
        }
        
        let cursor:Int = 0
        let total:Int = 0
        
        return try await zscanTotal(key, keywords: keywords, cursor: cursor, total: total)
    }
    
    
    private func zscanAsync(_ key:String, keywords:String?, cursor:Int, count:Int? = 1) async throws -> (Int, [(String, Double)?]) {
        
        logger.debug("redis set scan, key: \(key) cursor: \(cursor), keywords: \(String(describing: keywords)), count:\(String(describing: count))")
        
        let conn = try await getConn()
        
        return try await withCheckedThrowingContinuation { continuation in
            
            conn.zscan(RedisKey(key), startingFrom: cursor, matching: keywords, count: count, valueType: String.self)
                .whenComplete({completion in
                    if case .success(let r) = completion {
                        continuation.resume(returning: r)
                    }
                    else if case .failure(let error) = completion {
                        self.logger.error("redis set scan key:\(key) error: \(error)")
                        continuation.resume(throwing: error)
                    }
                })
            
        }
    }
    
    func zupdate(_ key:String, from:String, to:String, score:Double) async -> Bool {
        logger.info("update zset element key: \(key), from:\(from), to:\(to), score:\(score)")
        begin()
        defer {
            complete()
        }
 
        do {
            let r = try await zremInner(key, ele: from)
            if r > 0 {
                return try await zaddInner(key, score: score, ele: to)
            }
            
        } catch {
            handleError(error)
        }
        return false
    }
    
    func zadd(_ key:String, score:Double, ele:String) async -> Bool {
        begin()
        defer {
            complete()
        }
        do {
            return try await zaddInner(key, score: score, ele: ele)
        } catch {
            handleError(error)
        }
        
        return false
    }
    
    private func zaddInner(_ key:String, score:Double, ele:String) async throws -> Bool {
        let conn = try await getConn()
        
        return try await withCheckedThrowingContinuation { continuation in
            
            conn.zadd((element: ele, score: score), to: RedisKey(key))
                .whenComplete({completion in
                    if case .success(let r) = completion {
                        continuation.resume(returning: r)
                    }
                    else if case .failure(let error) = completion {
                        self.logger.error("redis zset zadd key:\(key) error: \(error)")
                        continuation.resume(throwing: error)
                    }
                })
            
        }
    }
    
    
    private func zcard(_ key:String) async throws -> Int {
        let conn = try await getConn()
        
        return try await withCheckedThrowingContinuation { continuation in
            
            conn.zcard(of: RedisKey(key))
                .whenComplete({completion in
                    if case .success(let r) = completion {
                        continuation.resume(returning: r)
                    }
                    
                    self.complete(completion, continuation: continuation)
                })
        }
    }
    
    func zrem(_ key:String, ele:String) async -> Int {
        begin()
        
        defer {
            complete()
        }
        do {
            return try await zremInner(key, ele: ele)
        } catch {
            handleError(error)
        }
        return 0
    }
    
    private func zremInner(_ key:String, ele:String) async throws -> Int {
        
        let conn = try await getConn()
        
        return try await withCheckedThrowingContinuation { continuation in
            
            conn.zrem(ele, from: RedisKey(key))
                .whenComplete({completion in
                    if case .success(let r) = completion {
                        continuation.resume(returning: r)
                    }
                    else if case .failure(let error) = completion {
                        continuation.resume(throwing: error)
                    }
                })
            
        }
        
    }
}

// set
extension RediStackClient {
    
    func pageSet(_ key:String, page: Page) async -> [String?] {
        
        logger.info("redis set page, key: \(key), page: \(page)")
        
        begin()
        defer {
            complete()
        }
        
        do {
            
            let match = page.keywords.isEmpty ? nil : page.keywords
            
            let set:[String?] = [String?]()
            let cursor:Int = 0
            let maxCount = page.current * page.size
            
            let res = try await recursionSScan(key, keywords: match, cursor: cursor, maxCount: maxCount, items: set)
            let start = (page.current - 1) * page.size
            
            if res.1.count <= start {
                return []
            }
            
            let end = min(start + page.size - 1, res.1.count)
            let pageData:[String?] = Array(res.1[start..<end])
            
            let total = try await recursionSScanTotal(key, keywords: match)
            page.total = total
            
            return pageData
        } catch {
            handleError(error)
        }
        return []
    }
    
    // 递归取出包含分页的数据
    private func recursionSScan(_ key:String, keywords:String?, cursor:Int, maxCount:Int, items:[String?]) async throws -> (Int, [String?]) {
        if items.count >= maxCount {
            self.logger.info("recursion sscan get keys enough, max count: \(maxCount), current count: \(items.count)")
            return (cursor, items)
        } else {
            let res = try await sscan(key, keywords: keywords, cursor: cursor, count: recursionSize)
            
            let newItems:[String?] = items + res.1
            
            if res.0 == 0 {
                self.logger.info("recursion scan reach end, max count: \(maxCount), current count: \(newItems.count)")
                
                return (res.0, newItems)
            }
            
            self.logger.info("recursion scan get more keys, current count: \(newItems.count)")
            return try await recursionSScan(key, keywords: keywords, cursor: res.0, maxCount: maxCount, items: newItems)
        }
    }
    
    private func sscanTotal(_ key:String, keywords:String?, cursor:Int, total:Int) async throws -> Int {
        let res = try await sscan(key, keywords: keywords, cursor: cursor, count: 1000)
        let newTotal:Int = total + res.1.count
        
        if res.0 == 0 {
            self.logger.info("recursion scan total reach end, total: \(newTotal)")
            
            return newTotal
        }
        
        self.logger.info("recursion scan total get more, current total: \(newTotal)")
        return try await sscanTotal(key, keywords: keywords, cursor: res.0, total: newTotal)
        
    }
    
    private func recursionSScanTotal(_ key:String, keywords:String?) async throws -> Int {
        if isMatchAll(keywords) {
            logger.info("keywords is match all, use scard...")
            return try await scard(key)
        }
        
        let cursor:Int = 0
        let total:Int = 0
        
        return try await sscanTotal(key, keywords: keywords, cursor: cursor, total: total)
    }
    
    private func sscan(_ key:String, keywords:String?, cursor:Int, count:Int? = 1) async throws -> (Int, [String?]) {
        logger.debug("redis set scan, key: \(key) cursor: \(cursor), keywords: \(String(describing: keywords)), count:\(String(describing: count))")
        let conn = try await getConn()
        
        return try await withCheckedThrowingContinuation { continuation in
            
            conn.sscan(RedisKey(key), startingFrom: cursor, matching: keywords, count: count, valueType: String.self)
                .whenComplete({completion in
                    if case .success(let r) = completion {
                        continuation.resume(returning: r)
                    }
                    
                    else if case .failure(let error) = completion {
                        self.logger.error("redis set scan key:\(key) error: \(error)")
                        continuation.resume(throwing: error)
                    }
                })
        }
    }
    
    func supdate(_ key:String, from:String, to:String) async -> Int {
        begin()
        defer {
            complete()
        }
        logger.info("redis set update, key: \(key), from: \(from), to: \(to)")
        
        do {
            let r = try await sremInner(key, ele: from)
            if r > 0 {
                return try await saddInner(key, ele: to)
            }
        } catch {
            handleError(error)
        }
        return 0
        
    }
    
    func srem(_ key:String, ele:String) async -> Int {
        begin()
        defer {
            complete()
        }
        
        do {
            return try await sremInner(key, ele: ele)
        } catch {
            handleError(error)
        }
        return 0
    }
    
    func sadd(_ key:String, ele:String) async -> Int {
        begin()
        defer {
            complete()
        }
        do {
            return try await saddInner(key, ele: ele)
        } catch {
            handleError(error)
        }
        return 0
    }
    
    private func scard(_ key:String) async throws -> Int {
        let conn = try await getConn()
        
        return try await withCheckedThrowingContinuation { continuation in
            
            conn.scard(of: RedisKey(key))
                .whenComplete({completion in
                    if case .success(let r) = completion {
                        continuation.resume(returning: r)
                    }
                    
                    else if case .failure(let error) = completion {
                        self.logger.error("redis scard error, key:\(key), error: \(error)")
                        continuation.resume(throwing: error)
                    }
                })
        }
    }
    
    private func sremInner(_ key:String, ele:String) async throws -> Int {
        let conn = try await getConn()
        
        return try await withCheckedThrowingContinuation { continuation in
            
            conn.srem(ele, from: RedisKey(key))
                .whenComplete({completion in
                    if case .success(let r) = completion {
                        continuation.resume(returning: r)
                    }
                    
                    else if case .failure(let error) = completion {
                        self.logger.error("redis set srem key:\(key), ele:\(ele), error: \(error)")
                        continuation.resume(throwing: error)
                    }
                })
        }
    }
    
    
    private func saddInner(_ key:String, ele:String) async throws -> Int {
        let conn = try await getConn()
        
        return try await withCheckedThrowingContinuation { continuation in
            
            conn.sadd(ele, to: RedisKey(key))
                .whenComplete({completion in
                    if case .success(let r) = completion {
                        continuation.resume(returning: r)
                    }
                    
                    else if case .failure(let error) = completion {
                        self.logger.error("redis set add key:\(key), ele:\(ele), error: \(error)")
                        continuation.resume(throwing: error)
                    }
                })
        }
    }
    
    
}

// list
extension RediStackClient {

    func pageList(_ key:String, page:Page) async -> [String?] {
        
        logger.info("redis list page, key: \(key), page: \(page)")
        begin()
        defer {
            complete()
        }
        do {
            let cursor:Int = (page.current - 1) * page.size
            let r1 = try await llen(key)
            let r2 = try await lrange(key, start: cursor, stop: cursor + page.size - 1)
            let total = r1
            page.total = total
            return r2
        } catch {
            handleError(error)
        }
        return []
    }
    
    private func lrange(_ key:String, start:Int, stop:Int) async throws -> [String?] {
        
        logger.debug("redis list range, key: \(key)")
        
        let conn = try await getConn()
        
        return try await withCheckedThrowingContinuation { continuation in
            
            conn.lrange(from: RedisKey(key), firstIndex: start, lastIndex: stop, as: String.self)
                .whenComplete({completion in
                    if case .success(let r) = completion {
                        continuation.resume(returning: r)
                    }
                    
                    else if case .failure(let error) = completion {
                        self.logger.error("redis list range error \(error)")
                        continuation.resume(throwing: error)
                    }
                })
        }
    }
    
    func ldel(_ key:String, index:Int) async -> Int {
        logger.debug("redis list delete, key: \(key), index:\(index)")
        
        begin()
        defer {
            complete()
        }
        
        do {
            try await lsetInner(key, index: index, value: Constants.LIST_VALUE_DELETE_MARK)
            
            let conn = try await getConn()
            return try await withCheckedThrowingContinuation { continuation in
                
                conn.lrem(Constants.LIST_VALUE_DELETE_MARK, from: RedisKey(key), count: 0)
                    .whenComplete({completion in
                        if case .success(let r) = completion {
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
    
    func lset(_ key:String, index:Int, value:String) async -> Void {
        begin()
        defer {
            complete()
        }
        do {
            try await lsetInner(key, index: index, value: value)
        } catch {
            handleError(error)
        }
    }
    
    private func lsetInner(_ key:String, index:Int, value:String) async throws -> Void {
        let conn = try await getConn()
        
        return try await withCheckedThrowingContinuation { continuation in
            
            conn.lset(index: index, to: value, in: RedisKey(key))
                .whenComplete({completion in
                    if case .success(let r) = completion {
                        continuation.resume(returning: r)
                    }
                    
                    else if case .failure(let error) = completion {
                        self.logger.error("redis list lset error \(error)")
                        continuation.resume(throwing: error)
                    }
                })
        }
    }
    
    func lpush(_ key:String, value:String) async -> Int {
        begin()
        defer {
            complete()
        }
        
        do {
            let conn = try await getConn()
            return try await withCheckedThrowingContinuation { continuation in
                
                conn.lpush(value, into: RedisKey(key))
                    .whenComplete({completion in
                        if case .success(let r) = completion {
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
    
    func rpush(_ key:String, value:String) async -> Int {
        begin()
        defer {
            complete()
        }
        
        do {
            let conn = try await getConn()
            return try await withCheckedThrowingContinuation { continuation in
                
                conn.rpush(value, into: RedisKey(key))
                    .whenComplete({completion in
                        if case .success(let r) = completion {
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
    
    private func llen(_ key:String) async throws -> Int {
        logger.debug("redis list length, key: \(key)")
        let conn = try await getConn()
        
        return try await withCheckedThrowingContinuation { continuation in
            
            conn.llen(of: RedisKey(key))
                .whenComplete({completion in
                    if case .success(let r) = completion {
                        continuation.resume(returning: r)
                    }
                    
                    else if case .failure(let error) = completion {
                        self.logger.error("redis list llen error \(error)")
                        continuation.resume(throwing: error)
                    }
                })
        }
    }
}

// system
extension RediStackClient {
    
    func selectDB(_ database: Int) async -> Bool {
        do {
            let conn = try await getConn()
            return try await withCheckedThrowingContinuation { continuation in
                
                conn.select(database: database)
                    .whenComplete({completion in
                        if case .success(let r) = completion {
                            self.logger.info("select redis database: \(database), r: \(r)")
                            continuation.resume(returning: true)
                        }
                        
                        self.complete(completion, continuation: continuation)
                    })
            }
        } catch {
            handleError(error)
        }
        return false
    }
    
    func databases() async -> Int {
        do {
            let conn = try await getConn()
            return try await withCheckedThrowingContinuation { continuation in
                
                conn.send(command: "CONFIG", with: [RESPValue(from: "GET"), RESPValue(from: "databases")])
                    .whenComplete({completion in
                        if case .success(let r) = completion {
                            let dbs = r.array
                            self.logger.info("get config databases: \(String(describing: dbs))")
                            continuation.resume(returning: NumberHelper.toInt(dbs?[1], defaultValue: 16))
                        }
                        
                        self.complete(completion, continuation: continuation)
                    })
            }
        } catch {
            handleError(error)
        }
        return 0
    }
    
    func dbsize() async -> Int {
        begin()
        defer {
            complete()
        }
        do {
            let conn = try await getConn()
            
            return try await withCheckedThrowingContinuation { continuation in
                
                conn.send(command: "dbsize")
                    .whenComplete({completion in
                        if case .success(let r) = completion {
                            let dbsize = r.int ?? 0
                            self.logger.info("query redis dbsize success: \(dbsize)")
                            continuation.resume(returning: dbsize)
                        }
                        else if case .failure(let error) = completion {
                            self.logger.error("query redis dbsize error: \(error)")
                            continuation.resume(returning: 0)
                        }
                    })
                
            }
        } catch {
            self.logger.error("query redis dbsize error: \(error)")
        }
        return 0
    }
    
    func flushDB() async -> Bool {
        begin()
        defer {
            complete()
        }
        do {
            let conn = try await getConn()
            
            return try await withCheckedThrowingContinuation { continuation in
                
                conn.send(command: "FLUSHDB")
                    .whenComplete({completion in
                        if case .success(let r) = completion {
                            self.logger.info("flush db success: \(r)")
                            continuation.resume(returning: true)
                        }
                        self.complete(completion, continuation: continuation)
                    })
                
            }
        } catch {
            handleError(error)
        }
        return false
    }
    
    func clientKill(_ clientModel:ClientModel) async -> Bool {
        begin()
        defer {
            complete()
        }
        do {
            let conn = try await getConn()
            
            return try await withCheckedThrowingContinuation { continuation in
                
                conn.send(command: "CLIENT", with: [RESPValue(from: "KILL"), RESPValue(from: "\(clientModel.addr)")])
                    .whenComplete({completion in
                        if case .success(let r) = completion {
                            self.logger.info("flush db success: \(r)")
                            continuation.resume(returning: true)
                        }
                        self.complete(completion, continuation: continuation)
                    })
                
            }
        } catch {
            handleError(error)
        }
        return false
    }
    
    func clientList() async -> [ClientModel] {
        begin()
        defer {
            complete()
        }
        do {
            let conn = try await getConn()
            
            return try await withCheckedThrowingContinuation { continuation in
                
                conn.send(command: "CLIENT", with: [RESPValue(from: "LIST")])
                    .whenComplete({completion in
                        if case .success(let r) = completion {
                            self.logger.info("query redis server client list success: \(r)")
                            let resStr = r.string ?? ""
                            let lines = resStr.components(separatedBy: "\n")
                            
                            var resArray = [ClientModel]()
                            
                            lines.forEach({ line in
                                if !line.contains("=") {
                                    return
                                }
                                resArray.append(ClientModel(line: line))
                            })

                            continuation.resume(returning: resArray)
                        }
                        self.complete(completion, continuation: continuation)
                    })
                
            }
        } catch {
            handleError(error)
        }
        return []
    }
    
    func info() async -> [RedisInfoModel] {
        begin()
        defer {
            complete()
        }
        do {
            let conn = try await getConn()
            
            return try await withCheckedThrowingContinuation { continuation in
                
                conn.send(command: "info")
                    .whenComplete({completion in
                        if case .success(let r) = completion {
                            self.logger.info("query redis server info success: \(r.string ?? "")")
                            let infoStr = r.string ?? ""
                            let lines = infoStr.components(separatedBy: "\n")
                            
                            var redisInfoModels = [RedisInfoModel]()
                            var item:RedisInfoModel?
                            
                            lines.forEach({ line in
                                if line.starts(with: "#") {
                                    if item != nil {
                                        redisInfoModels.append(item!)
                                    }
                                    
                                    let section = line.replacingOccurrences(of: "#", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                                    item = RedisInfoModel(section: section)
                                }
                                if line.contains(":") {
                                    let infoArr = line.components(separatedBy: ":")
                                    let redisInfoItemModel = RedisInfoItemModel(section: item?.section ?? "", key: infoArr[0].trimmingCharacters(in: .whitespacesAndNewlines), value: infoArr[1].trimmingCharacters(in: .whitespacesAndNewlines))
                                    item?.infos.append(redisInfoItemModel)
                                }
                            })
                            continuation.resume(returning: redisInfoModels)
                        }
                        self.complete(completion, continuation: continuation)
                    })
                
            }
        } catch {
            handleError(error)
        }
        return []
    }
    
    func resetState() async -> Bool {
        logger.info("reset state...")

        do {
            let conn = try await getConn()
            
            return try await withCheckedThrowingContinuation { continuation in
                
                conn.send(command: "CONFIG", with: [RESPValue(from: "RESETSTAT")])
                    .whenComplete({completion in
                        if case .success(let r) = completion {
                            self.logger.info("reset state res: \(r)")
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
    
    func ping() async -> Bool {
        begin()
    
        do {
            let conn = try await getConn()
            
            return try await withCheckedThrowingContinuation { continuation in
                conn.ping().whenComplete({completion in
                    if case .success(let pong) = completion {
                        continuation.resume(returning: "PONG".caseInsensitiveCompare(pong) == .orderedSame)
                    }
                    self.complete(completion, continuation:continuation)
                })
            }
        } catch {
            handleError(error)
        }
        
        return false
    }
    
}

// config
extension RediStackClient {
    func getConfigList(_ pattern:String = "*") async -> [RedisConfigItemModel] {
        logger.info("get redis config list, pattern: \(pattern)...")
        begin()
        defer {
            complete()
        }
        
        var _pattern = pattern
        if pattern.isEmpty {
            _pattern = "*"
        }
        
        do {
            let conn = try await getConn()
            
            return try await withCheckedThrowingContinuation { continuation in
                conn.send(command: "CONFIG", with: [RESPValue(from: "GET"), RESPValue(from: _pattern)])
                    .whenComplete({completion in
                    if case .success(let r) = completion {
                        self.logger.info("get redis config list res: \(r)")
                        
                        let configs = r.array ?? []
                        
                        var configList = [RedisConfigItemModel]()
                        
                        let max:Int = configs.count / 2
                        
                        for index in (0..<max) {
                            configList.append(RedisConfigItemModel(key: configs[ index * 2].string, value: configs[index * 2 + 1].string))
                        }
                        
                        continuation.resume(returning: configList)
                    }
                    self.complete(completion, continuation:continuation)
                })
            }
        } catch {
            handleError(error)
        }
        
        return []
    }
    
    func configRewrite() async -> Bool {
        logger.info("redis config rewrite ...")
        begin()
        defer {
            complete()
        }

        do {
            let conn = try await getConn()
            
            return try await withCheckedThrowingContinuation { continuation in
                conn.send(command: "CONFIG", with: [RESPValue(from: "REWRITE")])
                    .whenComplete({completion in
                    if case .success(let r) = completion {
                        self.logger.info("redis config rewrite res: \(r)")
                        continuation.resume(returning: r.string == "OK")
                    }
                    self.complete(completion, continuation:continuation)
                })
            }
        } catch {
            handleError(error)
        }
        
        return false
        
    }
    
    func getConfigOne(key:String) async -> String? {
        logger.info("get redis config ...")
        
        do {
            let conn = try await getConn()
            
            return try await withCheckedThrowingContinuation { continuation in
                conn.send(command: "CONFIG", with: [RESPValue(from: "GET"), RESPValue(from: key)])
                    .whenComplete({completion in
                    if case .success(let r) = completion {
                        self.logger.info("get redis config one res: \(r)")
                        continuation.resume(returning: r.array?[1].string)
                    }
                    self.complete(completion, continuation:continuation)
                })
            }
        } catch {
            handleError(error)
        }
        
        return nil
        
    }
    
    
    func setConfig(key:String, value:String) async -> Bool {
        logger.info("set redis config, key: \(key), value: \(value)")
        begin()
        defer {
            complete()
        }

        do {
            let conn = try await getConn()
            
            return try await withCheckedThrowingContinuation { continuation in
                conn.send(command: "CONFIG", with: [RESPValue(from: "SET"), RESPValue(from: key), RESPValue(from: value)])
                    .whenComplete({completion in
                    if case .success(let r) = completion {
                        self.logger.info("set config res: \(r)")
                        continuation.resume(returning: r.string == "OK")
                    }
                    self.complete(completion, continuation:continuation)
                })
            }
        } catch {
            handleError(error)
        }
        
        return false
    }
    
}


// slow log
extension RediStackClient {
    func slowLogReset() async -> Bool {
        logger.info("slow log reset ...")
        
        do {
            let conn = try await getConn()
            
            return try await withCheckedThrowingContinuation { continuation in
                conn.send(command: "SLOWLOG", with: [RESPValue(from: "RESET")])
                    .whenComplete({completion in
                    if case .success(let r) = completion {
                        self.logger.info("slow log reset res: \(r)")
                        continuation.resume(returning: r.string == "OK")
                    }
                    self.complete(completion, continuation:continuation)
                })
            }
        } catch {
            handleError(error)
        }
        
        return false
    }
    
    func slowLogLen() async -> Int {
        logger.info("get slow log len ...")
        do {
            let conn = try await getConn()
            
            return try await withCheckedThrowingContinuation { continuation in
                conn.send(command: "SLOWLOG", with: [RESPValue(from: "LEN")])
                    .whenComplete({completion in
                    if case .success(let r) = completion {
                        self.logger.info("slow log reset res: \(r)")
                        continuation.resume(returning: r.int ?? 0)
                    }
                    self.complete(completion, continuation:continuation)
                })
            }
        } catch {
            handleError(error)
        }
        
        return 0
        
    }
    
    func getSlowLog(_ size:Int) async -> [SlowLogModel] {
        logger.info("get slow log list ...")
        
        begin()
        defer {
            complete()
        }
        do {
            let conn = try await getConn()
            
            return try await withCheckedThrowingContinuation { continuation in
                conn.send(command: "SLOWLOG", with: [RESPValue(from: "GET"), RESPValue(from: size)])
                    .whenComplete({completion in
                    if case .success(let r) = completion {
                        self.logger.info("get slow log res: \(r)")
                        
                        var slowLogs = [SlowLogModel]()
                        r.array?.forEach({ item in
                            let itemArray = item.array
                            
                            let cmd = itemArray?[3].array!.map({
                                $0.string ?? MTheme.NULL_STRING
                            }).joined(separator: " ")
                            
                            slowLogs.append(SlowLogModel(id: itemArray?[0].string, timestamp: itemArray?[1].int, execTime: itemArray?[2].string, cmd: cmd, client: itemArray?[4].string, clientName: itemArray?[5].string))
                        })
                        
                        continuation.resume(returning: slowLogs)
                    }
                    self.complete(completion, continuation:continuation)
                })
            }
        } catch {
            handleError(error)
        }
        
        return []
    }
}
