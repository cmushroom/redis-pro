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
import PromiseKit
import NIOSSH

class RediStackClient{
    var redisModel:RedisModel
    var connection:RedisConnection?
    var globalContext:GlobalContext?
    
    let logger = Logger(label: "redis-client")
    
    init(redisModel:RedisModel) {
        self.redisModel = redisModel
    }
    
    func setUp(_ globalContext:GlobalContext) -> Void {
        self.globalContext = globalContext
    }
    
    /*
     * 初始化redis 连接
     */
    func initConnection() -> Promise<Bool> {
        return getConnectionAsync().then({connection in
            return Promise<Bool>.value(true)
        })
    }

    // string operator
    func set(_ key:String, value:String, ex:Int?) -> Promise<Void> {
        logger.info("set value, key:\(key), value:\(value), ex:\(ex ?? -1)")
        self.globalContext?.loading = true
        let promise = getConnectionAsync().then({connection in
            Promise<Void> {resolver in
                if (ex == nil || ex! == -1) {
                    connection.set(RedisKey(key), to: value)
                        .whenComplete({completion in
                            if case .success(let r) = completion {
                                resolver.fulfill(r)
                            }
                            else if case .failure(let error) = completion {
                                self.logger.error("redis string set error \(error)")
                                resolver.reject(error)
                            }
                        })
                } else {
                    connection.setex(RedisKey(key), to: value, expirationInSeconds: ex!)
                        .whenComplete({completion in
                            if case .success(let r) = completion {
                                resolver.fulfill(r)
                            }
                            else if case .failure(let error) = completion {
                                self.logger.error("redis string set error \(error)")
                                resolver.reject(error)
                            }
                        })
                }
            }
        })
        
        afterPromise(promise)
            
        return promise
       
    }
    
    func get(key:String) -> Promise<String> {
        self.globalContext?.loading = true
        let promise = getConnectionAsync().then({connection in
            Promise<String>{resolver in
                connection.get(RedisKey(key)).whenComplete({completion in
                    if case .success(let r) = completion {
                        self.logger.info("get value key: \(key) complete, r: \(r)")
                        if r.isNull {
                            resolver.reject(BizError(message: "Key `\(key)` is not exist!"))
                        } else {
                            resolver.fulfill(r.string!)
                        }
                    }
                    else if case .failure(let error) = completion {
                        self.logger.error("redis get string error \(error)")
                        resolver.reject(error)
                    }
                })
            }
        })
        
        afterPromise(promise)
        return promise
    }
    
    func del(key:String) -> Promise<Int> {
        self.logger.info("delete key \(key)")
        self.globalContext?.loading = true
        let promise = getConnectionAsync().then({connection in
            Promise<Int>{resolver in
                connection.delete(RedisKey(key)).whenComplete({completion in
                    if case .success(let r) = completion {
                        self.logger.info("delete redis key \(key) complete, r: \(r)")
                        resolver.fulfill(r)
                    }
                    else if case .failure(let error) = completion {
                        self.logger.error("redis get string error \(error)")
                        resolver.reject(error)
                    }
                })
            }
        })
        
        afterPromise(promise)
        return promise
    }
    
    func expire(_ key:String, seconds:Int) -> Promise<Bool> {
        logger.info("set key expire key:\(key), seconds:\(seconds)")
        self.globalContext?.loading = true
        
        let promise = getConnectionAsync().then({connection in
            Promise<Bool>{resolver in
                if seconds < 0 {
                    connection.send(command: "PERSIST", with: [RESPValue(from: key)]).whenComplete({completion in
                        if case .success(let r) = completion {
                            self.logger.info("clear key expire time \(key) complete, r: \(r)")
                            resolver.fulfill(true)
                        }
                        else if case .failure(let error) = completion {
                            self.logger.error("clear key expire time error \(error)")
                            resolver.reject(error)
                        }
                    })
                } else {
                    connection.expire(RedisKey(key), after: TimeAmount.seconds(Int64(seconds))).whenComplete({completion in
                        if case .success(let r) = completion {
                            self.logger.info("set key expire time \(key) complete, r: \(r)")
                            resolver.fulfill(true)
                        }
                        else if case .failure(let error) = completion {
                            self.logger.error("set key expire time error \(error)")
                            resolver.reject(error)
                        }
                    })
                }
            }
        })
        
        afterPromise(promise)
        return promise
    }
    
    func ttl(_ redisKeyModel:RedisKeyModel) -> Void {
        if redisKeyModel.isNew {
            return
        }

        let _ = ttl(key: redisKeyModel.key).done({r in
            redisKeyModel.ttl = r
        })
    }
    
    func ttl(key:String) -> Promise<Int> {
        logger.info("get ttl key: \(key)")
        
        let promise = getConnectionAsync().then({connection in
            Promise<Int>{resolver in
                connection.ttl(RedisKey(key)).whenComplete({completion in
                    if case .success(let r) = completion {
                        self.logger.info("query redis key ttl, key: \(key), r:\(r)")
                        if r == RedisKey.Lifetime.keyDoesNotExist {
                            resolver.reject(BizError(message: "redis key: \(key) does not exist!"))
                        } else if r == RedisKey.Lifetime.unlimited {
                            resolver.fulfill(-1)
                        } else {
                            resolver.fulfill(Int(r.timeAmount!.nanoseconds / 1000000000))
                        }
                    }
                    else if case .failure(let error) = completion {
                        self.logger.error("redis get key type error \(error)")
                        resolver.reject(error)
                    }
                })
            }
        })
        return promise
    }
    
    private func type(_ key:String) -> Promise<String> {
        let promise = getConnectionAsync().then({connection in
            Promise<String>{resolver in
                connection.send(command: "type", with: [RESPValue.init(from: key)]).whenComplete({completion in
                    if case .success(let r) = completion {
                        resolver.fulfill(r.string!)
                    }
                    else if case .failure(let error) = completion {
                        self.logger.error("redis get key type error \(error)")
                        resolver.fulfill(RedisKeyTypeEnum.NONE.rawValue)
                    }
                })
            }
        })
        
        return promise
    }
    
    func rename(_ oldKey:String, newKey:String) -> Promise<Bool> {
        logger.info("rename key, old key:\(oldKey), new key: \(newKey)")
        self.globalContext?.loading = true
        
        let promise = getConnectionAsync().then({connection in
            Promise<Bool> {resolver in
                connection.send(command: "RENAME", with: [RESPValue(from: oldKey), RESPValue(from: newKey)]).whenComplete({completion in
                    if case .success(let r) = completion {
                        resolver.fulfill(r.string == "OK")
                    }
                    else if case .failure(let error) = completion {
                        self.logger.error("redis keys scan error \(error)")
                        resolver.reject(error)
                    }
                })
            }
        })
        
        afterPromise(promise)
        return promise
    }
    
    func getConnectionAsync() -> Promise<RedisConnection> {
        if self.connection != nil && self.connection!.isConnected{
//            self.logger.info("get redis exist connection...")
            return Promise<RedisConnection>.value(self.connection!)
        } else {
            self.logger.info("get redis connection, but connection is not available...")
            self.close()
        }
        
        return Promise<RedisConnection>{ resolver in
            self.logger.info("start get new redis connection...")
            
            let eventLoop = MultiThreadedEventLoopGroup(numberOfThreads: 1).next()
            var configuration: RedisConnection.Configuration
            do {
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
                    resolver.fulfill(redisConnection)
                    self.logger.info("get new redis connection success")
                })
                future.whenFailure({ error in
                    self.logger.info("get new redis connection error: \(error)")
                    
                    resolver.reject(error)
                })
                
            } catch {
                self.logger.error("get new redis connection error \(error)")
                resolver.reject(error)
            }
        }
    }
    
    func getConnection() -> RedisConnection{
        return self.connection!
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
    }
    
    func afterPromise<T:CatchMixin>(_ promise:T) -> Void {
        promise
            .catch({error in
                self.globalContext?.showError(error)
            })
            .finally {
                self.globalContext?.loading = false
            }
    }
}

// key
extension RediStackClient {
    
    
    private func scanAsync(cursor:Int, keywords:String?, count:Int? = 1) -> Promise<(cursor:Int, keys:[String])> {
        logger.debug("redis keys scan, cursor: \(cursor), keywords: \(String(describing: keywords)), count:\(String(describing: count))")
        
        let promise =
            getConnectionAsync().then({ connection in
                Promise<(cursor:Int, keys:[String])> { resolver in
                    connection.scan(startingFrom: cursor, matching: keywords, count: count)
                        .whenComplete({ completion in
                            if case .success(let r) = completion {
                                resolver.fulfill(r)
                            }
                            else if case .failure(let error) = completion {
                                self.logger.error("redis keys scan error \(error)")
                                resolver.reject(error)
                            }
                        })
                }
                
            })
        
        return promise
    }
    
    private func scan(cursor:Int, keywords:String?, count:Int? = 1) throws -> (cursor:Int, keys:[String]) {
        logger.debug("redis keys scan, cursor: \(cursor), keywords: \(String(describing: keywords)), count:\(String(describing: count))")
        
        return try getConnection().scan(startingFrom: cursor, matching: keywords, count: count).wait()
    }
    
    // 递归取出包含分页的数据
    private func recursionScan(_ keywords:String?, cursor:Int, maxCount:Int, keys:[String]) -> Promise<(cursor:Int, keys:[String])> {
        if keys.count >= maxCount {
            self.logger.info("recursion scan get keys enough, max count: \(maxCount), current count: \(keys.count)")
            return Promise<(cursor:Int, keys:[String])> { resolver in
                resolver.fulfill((cursor, keys))
            }
        } else {
            return scanAsync(cursor: cursor, keywords: keywords, count: 3000).then{ res -> Promise<(cursor:Int, keys:[String])> in
                
                let newKeys = keys + res.keys
                
                if res.cursor == 0 {
                    self.logger.info("recursion scan reach end, max count: \(maxCount), current count: \(keys.count)")
                    
                    return Promise<(cursor:Int, keys:[String])> { resolver in
                        resolver.fulfill((res.cursor, newKeys))
                    }
                }
                
                self.logger.info("recursion scan get more keys, current count: \(newKeys.count)")
                return self.recursionScan(keywords, cursor: res.cursor, maxCount: maxCount, keys: newKeys)
            }
        }
    }
    
    private func scanTotal(_ keywords:String?, cursor:Int, total:Int) -> Promise<Int> {
        return scanAsync(cursor: cursor, keywords: keywords, count: 3000).then{ res -> Promise<Int> in
            let newTotal:Int = total + res.keys.count
            if res.cursor == 0 {
                self.logger.info("recursion scan total reach end, total: \(newTotal)")
                
                return Promise<Int> { resolver in
                    resolver.fulfill(newTotal)
                }
            }
            
            self.logger.info("recursion scan total get more, current total: \(newTotal)")
            return self.scanTotal(keywords, cursor: res.cursor, total: newTotal)
        }
    }
    
    private func isMatchAll(_ keywords:String?) -> Bool {
        return keywords == nil || keywords == "*" || keywords!.trimmingCharacters(in: .whitespacesAndNewlines) == "*"
    }
    
    private func recursionScanTotal(_ keywords:String?) -> Promise<Int> {
        if isMatchAll(keywords) {
            logger.info("keywords is match all, use dbsize...")
            return dbsizeAsync()
        }
        
        let cursor:Int = 0
        let total:Int = 0
        
        return scanTotal(keywords, cursor: cursor, total: total)
    }
   
    func pageKeys(_ page:Page) -> Promise<[RedisKeyModel]> {
        self.globalContext?.loading = true
        
        let stopwatch = Stopwatch.createStarted()
        
        logger.info("redis keys page scan, page: \(page)")
        
        let match = page.keywords.isEmpty ? nil : page.keywords
        
        let keys:[String] = [String]()
        let cursor:Int = 0
        let total:Int = page.current * page.size
        
        let scanPromise = Promise<[RedisKeyModel]> { resolver in
            let _ = self.recursionScan(match, cursor: cursor, maxCount: total, keys: keys).done {res in

                let start = (page.current - 1) * page.size
                
                if res.keys.count <= start {
                    resolver.fulfill([])
                    return
                }
                
                let end = min(start + page.size - 1, res.keys.count)
                let pageData:[String] = Array(res.keys[start..<end])
                
                let _ = self.toRedisKeyModels(pageData).done { r in
                    resolver.fulfill(r)
                }
            }
        }
        
        let promise = Promise<[RedisKeyModel]> { resolver in
            let _ = when(fulfilled: recursionScanTotal(match),  scanPromise).done({ r1, r2 in
                let total = r1
                page.total = total
//                page.cursor = cursor
                
                self.logger.info("keys scan complete, spend: \(stopwatch.elapsedMillis()) ms")
                resolver.fulfill(r2)
            })
        }
        
        afterPromise(promise)
        return promise
    }
    
    private func toRedisKeyModels(_ keys:[String]) -> Promise<[RedisKeyModel]> {
        if keys.isEmpty {
            return Promise<[RedisKeyModel]>.value([RedisKeyModel]())
        }
        
        var promises = [Promise<RedisKeyModel>]()
        
        for key in keys {
            promises.append(type(key).then({type in
                Promise<RedisKeyModel>.value(RedisKeyModel(key: key, type: type))
            }))
        }
        
        return when(resolved: promises).then({ r in
            Promise<[RedisKeyModel]>.value(r.map({
                if case .fulfilled(let v) = $0 {
                    return v
                } else {
                    return RedisKeyModel(key: "ERROR", type: RedisKeyTypeEnum.NONE.rawValue)
                }
            }))
        })
    }
    
}

// hash
extension RediStackClient {
    
    // hash operator
    func pageHash(_ redisKeyModel:RedisKeyModel, page:ScanModel) -> Promise<[RedisHashEntryModel]> {
        if redisKeyModel.isNew {
            return Promise<[RedisHashEntryModel]>.value([RedisHashEntryModel]())
        }
        
        return pageHash(redisKeyModel.key, page: page)
    }
    
    func pageHash(_ key:String, page:ScanModel) -> Promise<[RedisHashEntryModel]> {
        logger.info("redis hash field page scan, key: \(key), page: \(page)")
        
        self.globalContext?.loading = true
        
        let match = page.keywords.isEmpty ? nil : page.keywords
        
        let cursor:Int = page.cursor
        let fields:[(String, String?)] = []
        
        let scanPromise = Promise<[RedisHashEntryModel]> { resolver in
            let _ = self.recursionHScan(key, keywords: match, cursor: cursor, maxCount: page.size, fields: fields).done {res in

                page.cursor = res.0
                
                let pageData:[(String, String?)] = res.1
                let r:[RedisHashEntryModel] = pageData.sorted(by: {$0.0 > $1.0}).map({
                    RedisHashEntryModel(field: $0.0, value: $0.1)
                })
                
                resolver.fulfill(r)
            }
        }
        
        let promise = Promise<[RedisHashEntryModel]> { resolver in
            let _ = when(fulfilled: self.recursionHScanTotal(key, keywords: match),  scanPromise).done({ r1, r2 in
                let total = r1
                page.total = total
                
                resolver.fulfill(r2)
            })
        }
        afterPromise(promise)
        return promise
    }
    
    func hset(_ key:String, field:String, value:String) -> Promise<Bool> {
        logger.info("redis hash hset key:\(key), field:\(field), value:\(value)")
        self.globalContext?.loading = true
        
        let promise = getConnectionAsync().then({connection in
            Promise<Bool> {resolver in
                connection.hset(field, to: value, in: RedisKey(key))
                    .whenComplete({completion in
                        if case .success(let r) = completion {
                            resolver.fulfill(r)
                        }
                        else if case .failure(let error) = completion {
                            self.logger.error("redis hash set error \(error)")
                            resolver.reject(error)
                        }
                    })
            }
        })
        
        afterPromise(promise)
        return promise
    }
    
    func hdel(_ key:String, field:String) -> Promise<Int> {
        logger.info("redis hash hdel key:\(key), field:\(field)")
        self.globalContext?.loading = true
        
        let promise = getConnectionAsync().then({connection in
            Promise<Int> {resolver in
                connection.hdel(field, from: RedisKey(key))
                    .whenComplete({completion in
                        if case .success(let r) = completion {
                            resolver.fulfill(r)
                        }
                        else if case .failure(let error) = completion {
                            self.logger.error("redis hash del error \(error)")
                            resolver.reject(error)
                        }
                    })
            }
        })
        
        afterPromise(promise)
        return promise
    }
    
    // 递归取出包含分页的数据
    private func recursionHScan(_ key:String, keywords:String?, cursor:Int, maxCount:Int, fields:[(String, String?)]) -> Promise<(Int, [(String, String?)])> {
        if fields.count >= maxCount {
            self.logger.info("recursion scan get keys enough, max count: \(maxCount), current count: \(fields.count)")
            return Promise<(Int, [(String, String?)])> { resolver in
                resolver.fulfill((cursor, fields))
            }
        } else {
            return hscanAsync(key, keywords: keywords, cursor: cursor, count: maxCount).then{ res -> Promise<(Int, [(String, String?)])> in
                
                let newFields:[(String, String?)] = fields + res.1.map{$0}

                if res.0 == 0 {
                    self.logger.info("recursion hscan reach end, max count: \(maxCount), current count: \(newFields.count)")
                    
                    return Promise<(Int, [(String, String?)])> { resolver in
                        resolver.fulfill((res.0, newFields))
                    }
                }
                
                self.logger.info("recursion hscan get more keys, current count: \(newFields.count)")
                return self.recursionHScan(key, keywords: keywords, cursor: res.0, maxCount: maxCount, fields: newFields)
            }
        }
    }
    
    private func hscanTotal(_ key:String, keywords:String?, cursor:Int, total:Int) -> Promise<Int> {
        return hscanAsync(key, keywords: keywords, cursor: cursor, count: 1000).then{ res -> Promise<Int> in
            let newTotal:Int = total + res.1.count
            if res.0 == 0 {
                self.logger.info("recursion scan total reach end, total: \(newTotal)")
                
                return Promise<Int> { resolver in
                    resolver.fulfill(newTotal)
                }
            }
            
            self.logger.info("recursion scan total get more, current total: \(newTotal)")
            return self.hscanTotal(key, keywords: keywords, cursor: res.0, total: newTotal)
        }
    }
    
    private func recursionHScanTotal(_ key:String, keywords:String?) -> Promise<Int> {
        if isMatchAll(keywords) {
            logger.info("hscan total key: \(key), keywords is match all, use hlen...")
            return hlen(key)
        }
        
        let cursor:Int = 0
        let total:Int = 0
        
        return hscanTotal(key, keywords: keywords, cursor: cursor, total: total)
    }
    
    private func hlen(_ key:String) -> Promise<Int> {
        return getConnectionAsync().then({connection in
            Promise<Int> {resolver in
                connection.hlen(of: RedisKey(key))
                    .whenComplete({completion in
                        if case .success(let r) = completion {
                            resolver.fulfill(r)
                        }
                        else if case .failure(let error) = completion {
                            self.logger.error("redis hash hlen error \(error)")
                            resolver.reject(error)
                        }
                    })
            }
        })
    }
    
    private func hscanAsync(_ key:String, keywords:String?, cursor:Int, count:Int? = 1) -> Promise<(Int, [String: String?])> {
        logger.debug("redis hash scan, key: \(key) cursor: \(cursor), keywords: \(String(describing: keywords)), count:\(String(describing: count))")
        return getConnectionAsync().then({connection in
            Promise<(Int, [String: String?])>{ resolver in
                connection.hscan(RedisKey(key), startingFrom: cursor, matching: keywords, count: count, valueType: String.self)
                    .whenComplete({completion in
                        if case .success(let r) = completion {
                            resolver.fulfill(r)
                        }
                        else if case .failure(let error) = completion {
                            self.logger.error("redis hash scan error \(error)")
                            resolver.reject(error)
                        }
                    })
            }
        })
    }
    
    private func hscan(_ key:String, cursor:Int, count:Int? = 1, keywords:String?) throws -> (Int, [String: String?]) {
        do {
            logger.debug("redis hash scan, key: \(key) cursor: \(cursor), keywords: \(String(describing: keywords)), count:\(String(describing: count))")
            
            return try getConnection().hscan(RedisKey(key), startingFrom: cursor, matching: keywords, count: count, valueType: String.self).wait()
            
        } catch {
            logger.error("redis hash scan key:\(key) error: \(error)")
            throw error
        }
    }
    
    func hget(_ key:String, field:String) -> Promise<String> {
        logger.info("get hash field value, key:\(key), field: \(field)")
        self.globalContext?.loading = true
        let promise = getConnectionAsync().then({connection in
            Promise<String> {resolver in
                connection.hget(field, from: RedisKey(key)).whenComplete({completion in
                    if case .success(let r) = completion {
                        self.logger.info("hget value key: \(key), field: \(field) complete, r: \(r)")
                        resolver.fulfill(r.string!)
                    }
                    else if case .failure(let error) = completion {
                        self.logger.error("redis hash get field error, key: \(key), field: \(field), error: \(error)")
                        resolver.reject(error)
                    }
                })
            }
        })
        
        afterPromise(promise)
        return promise
    }
}

// zset
extension RediStackClient {
    
    // zset operator
    func pageZSet(_ redisKeyModel:RedisKeyModel, page:Page) -> Promise<[RedisZSetItemModel]> {
        if redisKeyModel.isNew {
            return Promise<[RedisZSetItemModel]>.value([RedisZSetItemModel]())
        }
        return pageZSet(redisKeyModel.key, page: page)
    }
    
    func pageZSet(_ key:String, page: Page) -> Promise<[RedisZSetItemModel]> {
        logger.info("redis zset scan page, key: \(key), page: \(page)")
        
        self.globalContext?.loading = true
        let match = page.keywords.isEmpty ? nil : page.keywords
        
        let cursor:Int = 0
        let items:[(String, Double)?] = []
        let maxCount = page.current * page.size
        
        let scanPromise = recursionZScan(key, keywords: match, cursor: cursor, maxCount: maxCount, items: items).then {res in
            Promise<[RedisZSetItemModel]>{ resolver in
                let start = (page.current - 1) * page.size
                
                if res.1.count <= start {
                    resolver.fulfill([])
                    return
                }
                
                let end = min(start + page.size - 1, res.1.count)
                let pageData:[RedisZSetItemModel] = Array(res.1[start..<end]).map {
                    RedisZSetItemModel(value: $0?.0 ?? "", score: "\($0?.1 ?? 0)")
                }
                
                resolver.fulfill(pageData)
            }
        }
        
        
        let promise = Promise<[RedisZSetItemModel]> { resolver in
            let _ = when(fulfilled: recursionZScanTotal(key, keywords: match),  scanPromise).done({ r1, r2 in
                let total = r1
                page.total = total
//                page.cursor = cursor
                
                resolver.fulfill(r2)
            })
        }
        afterPromise(promise)
        return promise
    }
    
    // 递归取出包含分页的数据
    private func recursionZScan(_ key:String, keywords:String?, cursor:Int, maxCount:Int, items:[(String, Double)?]) -> Promise<(Int, [(String, Double)?])> {
        if items.count >= maxCount {
            self.logger.info("recursion zscan get items enough, max count: \(maxCount), current count: \(items.count)")
            return Promise<(Int, [(String, Double)?])> { resolver in
                resolver.fulfill((cursor, items))
            }
        } else {
            return zscanAsync(key, keywords: keywords, cursor: cursor, count: 1000).then{ res -> Promise<(Int, [(String, Double)?])> in
                
                let newItems:[(String, Double)?] = items + res.1
                
                if res.0 == 0 {
                    self.logger.info("recursion zscan reach end, max count: \(maxCount), current count: \(newItems.count)")
                    
                    return Promise<(Int, [(String, Double)?])> { resolver in
                        resolver.fulfill((res.0, newItems))
                    }
                }
                
                self.logger.info("recursion zscan get more keys, current count: \(newItems.count)")
                return self.recursionZScan(key, keywords: keywords, cursor: res.0, maxCount: maxCount, items: newItems)
            }
        }
    }
    
    private func zscanTotal(_ key:String, keywords:String?, cursor:Int, total:Int) -> Promise<Int> {
        return zscanAsync(key, keywords: keywords, cursor: cursor, count: 1000).then{ res -> Promise<Int> in
            let newTotal:Int = total + res.1.count
            
            if res.0 == 0 {
                self.logger.info("recursion zscan total reach end, total: \(newTotal)")
                
                return Promise<Int> { resolver in
                    resolver.fulfill(newTotal)
                }
            }
            
            self.logger.info("recursion zscan total get more, current total: \(newTotal)")
            return self.zscanTotal(key, keywords: keywords, cursor: res.0, total: newTotal)
        }
    }
    
    private func recursionZScanTotal(_ key:String, keywords:String?) -> Promise<Int> {
        if isMatchAll(keywords) {
            logger.info("keywords is match all, use scard...")
            return zcard(key)
        }
        
        let cursor:Int = 0
        let total:Int = 0
        
        return zscanTotal(key, keywords: keywords, cursor: cursor, total: total)
    }
    
    
    func zscanAsync(_ key:String, keywords:String?, cursor:Int, count:Int? = 1) -> Promise<(Int, [(String, Double)?])> {
        
        logger.debug("redis set scan, key: \(key) cursor: \(cursor), keywords: \(String(describing: keywords)), count:\(String(describing: count))")
        
        let promise = getConnectionAsync().then({ connection in
            Promise<(Int, [(String, Double)?])>{ resolver in
                connection.zscan(RedisKey(key), startingFrom: cursor, matching: keywords, count: count, valueType: String.self)
                    .whenComplete({ completion in
                        if case .success(let r) = completion {
                            resolver.fulfill(r)
                        }
                        else if case .failure(let error) = completion {
                            self.logger.error("redis set scan key:\(key) error: \(error)")
                            resolver.reject(error)
                        }
                    })
                
            }
        })
        
        return promise
    }
    
    func zscan(_ key:String, cursor:Int, count:Int? = 1, keywords:String?) throws -> (Int, [(String, Double)?]) {
        do {
            logger.debug("redis set scan, key: \(key) cursor: \(cursor), keywords: \(String(describing: keywords)), count:\(String(describing: count))")

            return try getConnection().zscan(RedisKey(key), startingFrom: cursor, matching: keywords, count: count, valueType: String.self).wait()

        } catch {
            logger.error("redis set scan key:\(key) error: \(error)")
            throw error
        }
    }
    
    func zupdate(_ key:String, from:String, to:String, score:Double) throws -> Promise<Bool> {
        logger.info("update zset element key: \(key), from:\(from), to:\(to), score:\(score)")
        self.globalContext?.loading = true
        
        let promise = zremInner(key, ele: from).then({ _ in
            self.zadd(key, score: score, ele: to)
        })
        
        afterPromise(promise)
        
        return promise
    }
    
    func zadd(_ key:String, score:Double, ele:String) -> Promise<Bool> {
        self.globalContext?.loading = true
        
        let promise = zaddInner(key, score: score, ele: ele)
        
        afterPromise(promise)
        
        return promise
    }
    
    private func zaddInner(_ key:String, score:Double, ele:String) -> Promise<Bool> {
        return getConnectionAsync().then({ connection in
            Promise<Bool> { resolver in
                connection.zadd((element: ele, score: score), to: RedisKey(key))
                    .whenComplete({ completion in
                        if case .success(let r) = completion {
                            resolver.fulfill(r)
                        }
                        else if case .failure(let error) = completion {
                            self.logger.error("redis zset zadd key:\(key) error: \(error)")
                            resolver.reject(error)
                        }
                    })
            }
        })
    }
    
    
    private func zcard(_ key:String) -> Promise<Int> {
        return getConnectionAsync().then({ connection in
            Promise<Int> { resolver in
                connection.zcard(of: RedisKey(key))
                    .whenComplete({ completion in
                        if case .success(let r) = completion {
                            resolver.fulfill(r)
                        }
                        else if case .failure(let error) = completion {
                            self.logger.error("redis zcard key:\(key) error: \(error)")
                            resolver.reject(error)
                        }
                    })
            }
        })
    }
    
    func zrem(_ key:String, ele:String) -> Promise<Int> {
        self.globalContext?.loading = true
        
        let promise = zremInner(key, ele: ele)
        
        afterPromise(promise)
        
        return promise
    }
    
    private func zremInner(_ key:String, ele:String) -> Promise<Int> {
        return getConnectionAsync().then({ connection in
            Promise<Int> { resolver in
                connection.zrem(ele, from: RedisKey(key))
                    .whenComplete({ completion in
                        if case .success(let r) = completion {
                            resolver.fulfill(r)
                        }
                        else if case .failure(let error) = completion {
                            self.logger.error("redis zset zrem key:\(key), ele:\(ele), error: \(error)")
                            resolver.reject(error)
                        }
                    })
            }
        })
    }
}

// set
extension RediStackClient {
    func pageSet(_ redisKeyModel:RedisKeyModel, page: Page) -> Promise<[String?]> {
        if redisKeyModel.isNew {
            return Promise<[String?]>.value([String?]())
        }
        return pageSet(redisKeyModel.key, page: page)
    }
    
    func pageSet(_ key:String, page: Page) -> Promise<[String?]> {
        
        logger.info("redis set page, key: \(key), page: \(page)")
        
        self.globalContext?.loading = true
        
        let match = page.keywords.isEmpty ? nil : page.keywords
        
        let set:[String?] = [String?]()
        let cursor:Int = 0
        let maxCount = page.current * page.size
        
        let scanPromise = recursionSScan(key, keywords: match, cursor: cursor, maxCount: maxCount, items: set).then { res in
            Promise<[String?]>{ resolver in
                let start = (page.current - 1) * page.size
                
                if res.1.count <= start {
                    resolver.fulfill([])
                    return
                }
                
                let end = min(start + page.size - 1, res.1.count)
                let pageData:[String?] = Array(res.1[start..<end])
                
                resolver.fulfill(pageData)
            }
        }
        
//        let scanPromise = sscanAsync(key, keywords: match, cursor: cursor, count: page.size).then({ res in
//            Promise<[String?]>{ resolver in
//                cursor = res.0
//                set = res.1
//
//
//                // 如果取出数量不够 page.size, 继续迭带补满
//                if cursor != 0 && set.count < page.size {
//                    while true {
//                        let moreRes:(Int, [String?]) = try self.sscan(key, cursor:cursor, count: 1, keywords: match)
//
//                        set.append(contentsOf: moreRes.1)
//                        cursor = moreRes.0
//                        page.cursor = cursor
//                        if cursor == 0 || set.count == page.size {
//                            resolver.fulfill(set)
//                            break
//                        }
//                    }
//                } else {
//                    resolver.fulfill(set)
//                }
//            }
//        })
        
        
//        let countPromise =
//            getConnectionAsync().then({ connection in
//                Promise<Int> { resolver in
//                    connection.scard(of: RedisKey(key))
//                        .whenComplete({ completion in
//                            if case .success(let r) = completion {
//                                resolver.fulfill(r)
//                            }
//                            else if case .failure(let error) = completion {
//                                self.logger.error("redis set card key:\(key) error: \(error)")
//                                resolver.reject(error)
//                            }
//                        })
//                }
//            })
        
        
        
        let promise = Promise<[String?]> { resolver in
            let _ = when(fulfilled: recursionSScanTotal(key, keywords: match),  scanPromise).done({ r1, r2 in
                let total = r1
                page.total = total
//                page.cursor = cursor
                
                resolver.fulfill(r2)
            })
        }
        afterPromise(promise)
        return promise
    }
    
    // 递归取出包含分页的数据
    private func recursionSScan(_ key:String, keywords:String?, cursor:Int, maxCount:Int, items:[String?]) -> Promise<(Int, [String?])> {
        if items.count >= maxCount {
            self.logger.info("recursion sscan get keys enough, max count: \(maxCount), current count: \(items.count)")
            return Promise<(Int, [String?])> { resolver in
                resolver.fulfill((cursor, items))
            }
        } else {
            return sscanAsync(key, keywords: keywords, cursor: cursor, count: 3000).then{ res -> Promise<(Int, [String?])> in
                
                let newItems:[String?] = items + res.1
                
                if res.0 == 0 {
                    self.logger.info("recursion scan reach end, max count: \(maxCount), current count: \(newItems.count)")
                    
                    return Promise<(Int, [String?])> { resolver in
                        resolver.fulfill((res.0, newItems))
                    }
                }
                
                self.logger.info("recursion scan get more keys, current count: \(newItems.count)")
                return self.recursionSScan(key, keywords: keywords, cursor: res.0, maxCount: maxCount, items: newItems)
            }
        }
    }
    
    private func sscanTotal(_ key:String, keywords:String?, cursor:Int, total:Int) -> Promise<Int> {
        return sscanAsync(key, keywords: keywords, cursor: cursor, count: 1000).then{ res -> Promise<Int> in
            let newTotal:Int = total + res.1.count
            
            if res.0 == 0 {
                self.logger.info("recursion scan total reach end, total: \(newTotal)")
                
                return Promise<Int> { resolver in
                    resolver.fulfill(newTotal)
                }
            }
            
            self.logger.info("recursion scan total get more, current total: \(newTotal)")
            return self.sscanTotal(key, keywords: keywords, cursor: res.0, total: newTotal)
        }
    }
    
    private func recursionSScanTotal(_ key:String, keywords:String?) -> Promise<Int> {
        if isMatchAll(keywords) {
            logger.info("keywords is match all, use scard...")
            return scard(key)
        }
        
        let cursor:Int = 0
        let total:Int = 0
        
        return sscanTotal(key, keywords: keywords, cursor: cursor, total: total)
    }
    
    func sscanAsync(_ key:String, keywords:String?, cursor:Int, count:Int? = 1) -> Promise<(Int, [String?])> {
        logger.debug("redis set scan, key: \(key) cursor: \(cursor), keywords: \(String(describing: keywords)), count:\(String(describing: count))")
        return getConnectionAsync().then({connection in
            Promise<(Int, [String?])> { resolver in
                connection.sscan(RedisKey(key), startingFrom: cursor, matching: keywords, count: count, valueType: String.self)
                    .whenComplete({completion in
                        if case .success(let r) = completion {
                            resolver.fulfill(r)
                        }
                        else if case .failure(let error) = completion {
                            self.logger.error("redis set scan key:\(key) error: \(error)")
                            resolver.reject(error)
                        }
                    })
            }
        })
    }
    
    func sscan(_ key:String, cursor:Int, count:Int? = 1, keywords:String?) throws -> (Int, [String?]) {
        do {
            logger.debug("redis set scan, key: \(key) cursor: \(cursor), keywords: \(String(describing: keywords)), count:\(String(describing: count))")
            
            return try getConnection().sscan(RedisKey(key), startingFrom: cursor, matching: keywords, count: count, valueType: String.self).wait()
            
        } catch {
            logger.error("redis set scan key:\(key) error: \(error)")
            throw error
        }
    }
    
    func supdate(_ key:String, from:String, to:String) -> Promise<Int> {
        self.globalContext?.loading = true
        logger.info("redis set update, key: \(key), from: \(from), to: \(to)")
        
        let promise = sremInner(key, ele: from).then({ _ in
            self.sadd(key, ele: to)
        })
        
        return promise
    }
    
    private func scard(_ key:String) -> Promise<Int> {
        return getConnectionAsync().then({connection in
            Promise<Int> {resolver in
                connection.scard(of: RedisKey(key))
                    .whenComplete({completion in
                        if case .success(let r) = completion {
                            resolver.fulfill(r)
                        }
                        else if case .failure(let error) = completion {
                            self.logger.error("redis scard error, key:\(key), error: \(error)")
                            resolver.reject(error)
                        }
                    })
            }
        })
    }
    
    func srem(_ key:String, ele:String) -> Promise<Int> {
        self.globalContext?.loading = true
        
        let promise = sremInner(key, ele: ele)
        
        afterPromise(promise)
        
        return promise
    }

    
    private func sremInner(_ key:String, ele:String) -> Promise<Int> {
        return getConnectionAsync().then({connection in
            Promise<Int> {resolver in
                connection.srem(ele, from: RedisKey(key))
                    .whenComplete({completion in
                        if case .success(let r) = completion {
                            resolver.fulfill(r)
                        }
                        else if case .failure(let error) = completion {
                            self.logger.error("redis set srem key:\(key), ele:\(ele), error: \(error)")
                            resolver.reject(error)
                        }
                    })
            }
        })
    }
    
    func sadd(_ key:String, ele:String) -> Promise<Int> {
        self.globalContext?.loading = true
        
        let promise = saddInner(key, ele: ele)
        
        afterPromise(promise)
        
        return promise
    }
    
    private func saddInner(_ key:String, ele:String) -> Promise<Int> {
        return getConnectionAsync().then({connection in
            Promise<Int> {resolver in
                connection.sadd(ele, to: RedisKey(key))
                    .whenComplete({completion in
                        if case .success(let r) = completion {
                            resolver.fulfill(r)
                        }
                        else if case .failure(let error) = completion {
                            self.logger.error("redis set add key:\(key), ele:\(ele), error: \(error)")
                            resolver.reject(error)
                        }
                    })
            }
        })
    }
    
    
}

// list
extension RediStackClient {
    func pageList(_ redisKeyModel:RedisKeyModel, page:Page) -> Promise<[String?]> {
        if redisKeyModel.isNew {
            return Promise<[String?]>.value([String?]())
        }
        return pageList(redisKeyModel.key, page: page)
    }
    
    func pageList(_ key:String, page:Page) -> Promise<[String?]> {
        
        logger.info("redis list page, key: \(key), page: \(page)")
        self.globalContext?.loading = true
        
        let cursor:Int = (page.current - 1) * page.size
        
        
        let promise =
            Promise<[String?]> {resolver in
                let _ = when(fulfilled: llen(key), lrange(key, start: cursor, stop: cursor + page.size - 1)).done({ r1, r2 in
                    let total = r1
                    page.total = total
                    resolver.fulfill(r2)
                })
                
            }
        afterPromise(promise)
        return promise
    }
    
    private func lrange(_ key:String, start:Int, stop:Int) -> Promise<[String?]> {
        
        logger.debug("redis list range, key: \(key)")
        
        return getConnectionAsync().then({connection in
            Promise<[String?]> {resolver in
                connection.lrange(from: RedisKey(key), firstIndex: start, lastIndex: stop, as: String.self)
                    .whenComplete({completion in
                        if case .success(let r) = completion {
                            resolver.fulfill(r)
                        }
                        else if case .failure(let error) = completion {
                            self.logger.error("redis list lrem error \(error)")
                            resolver.reject(error)
                        }
                    })
            }
        })
    }
    
    func ldel(_ key:String, index:Int) -> Promise<Int> {
        logger.debug("redis list delete, key: \(key), index:\(index)")
        
        let promise = lsetInner(key, index: index, value: Constants.LIST_VALUE_DELETE_MARK).then({ _ in
            self.getConnectionAsync().then({connection in
                Promise<Int> {resolver in
                    connection.lrem(Constants.LIST_VALUE_DELETE_MARK, from: RedisKey(key), count: 0)
                        .whenComplete({completion in
                            if case .success(let r) = completion {
                                resolver.fulfill(r)
                            }
                            else if case .failure(let error) = completion {
                                self.logger.error("redis list lrem error \(error)")
                                resolver.reject(error)
                            }
                        })
                }
            })
        })
        
        afterPromise(promise)
        return promise
    }
    
    func lset(_ key:String, index:Int, value:String) -> Promise<Void> {
        self.globalContext?.loading = true
        
        let promise = lsetInner(key, index: index, value: value)
        afterPromise(promise)
        return promise
    }
    
    private func lsetInner(_ key:String, index:Int, value:String) -> Promise<Void> {
        let promise = getConnectionAsync().then({connection in
            Promise<Void> {resolver in
                connection.lset(index: index, to: value, in: RedisKey(key))
                    .whenComplete({completion in
                        if case .success(let r) = completion {
                            resolver.fulfill(r)
                        }
                        else if case .failure(let error) = completion {
                            self.logger.error("redis list lset error \(error)")
                            resolver.reject(error)
                        }
                    })
            }
        })
        
        return promise
    }
    
    func lpush(_ key:String, value:String) -> Promise<Int> {
        self.globalContext?.loading = true
        
        let promise = getConnectionAsync().then({connection in
            Promise<Int> {resolver in
                connection.lpush(value, into: RedisKey(key))
                    .whenComplete({completion in
                        if case .success(let r) = completion {
                            resolver.fulfill(r)
                        }
                        else if case .failure(let error) = completion {
                            self.logger.error("redis list lpush error \(error)")
                            resolver.reject(error)
                        }
                    })
            }
        })
        
        afterPromise(promise)
        return promise
    }
    
    func rpush(_ key:String, value:String) -> Promise<Int> {
        self.globalContext?.loading = true
        
        let promise = getConnectionAsync().then({connection in
            Promise<Int> {resolver in
                connection.rpush(value, into: RedisKey(key))
                    .whenComplete({completion in
                        if case .success(let r) = completion {
                            resolver.fulfill(r)
                        }
                        else if case .failure(let error) = completion {
                            self.logger.error("redis list rpush error \(error)")
                            resolver.reject(error)
                        }
                    })
            }
        })
        
        afterPromise(promise)
        return promise
    }
    
    private func llen(_ key:String) -> Promise<Int> {
        logger.debug("redis list length, key: \(key)")
        
        return getConnectionAsync().then({connection in
            Promise<Int> {resolver in
                connection.llen(of: RedisKey(key)).whenComplete({completion in
                    if case .success(let r) = completion {
                        resolver.fulfill(r)
                    }
                    else if case .failure(let error) = completion {
                        self.logger.error("redis list llen error \(error)")
                        resolver.reject(error)
                    }
                })
            }
        })
    }
}

// system
extension RediStackClient {
    
    func selectDB(_ database: Int) -> Promise<Void> {
        let promise = getConnectionAsync().then({connection in
            Promise<Void> {resolver in
                connection.select(database: database).whenComplete{ completion in
                    if case .success(let r) = completion {
                        self.logger.info("select redis database: \(database)")
                        
                        resolver.fulfill(r)
                    }
                    else if case .failure(let error) = completion {
                        resolver.reject(error)
                    }
                }
                
            }
        })
        
        afterPromise(promise)
        return promise
    }
    
    func databases() -> Promise<Int> {
        let promise =
            getConnectionAsync().then({connection in
                Promise<Int> { resolver in
                    connection.send(command: "CONFIG", with: [RESPValue(from: "GET"), RESPValue(from: "databases")])
                        .whenComplete{ completion in
                            if case .success(let r) = completion {
                                let dbs = r.array
                                self.logger.info("get config databases: \(String(describing: dbs))")
                                
                                resolver.fulfill(NumberHelper.toInt(dbs?[1], defaultValue: 16))
                            }
                            else if case .failure(let error) = completion {
                                resolver.reject(error)
                            }
                        }
                }
            })
        
        afterPromise(promise)
        return promise
    }
    
    func dbsizeAsync() -> Promise<Int> {
        let promise =
            getConnectionAsync().then({connection in
                Promise<Int> { resolver in
                    connection.send(command: "dbsize")
                        .whenComplete{ completion in
                            if case .success(let res) = completion {
                                self.logger.info("query redis dbsize success: \(res.int!)")
                                resolver.fulfill(res.int!)
                            }
                            else if case .failure(let error) = completion {
                                resolver.reject(error)
                            }
                        }
                }
            })
        
        
        return promise
    }
    
    func flushDB() -> Promise<Bool> {
        self.globalContext?.loading = true
        
        let promise = getConnectionAsync().then({connection in
            Promise<Bool> {resolver in
                connection.send(command: "FLUSHDB")
                    .whenComplete { completion in
                        if case .success(let res) = completion {
                            self.logger.info("flush db success: \(res)")
                            resolver.fulfill(true)
                        }
                        else if case .failure(let error) = completion {
                            resolver.reject(error)
                        }
                    }
            }
        })
        
        afterPromise(promise)
        return promise
    }
    
    func clientKill(_ clientModel:ClientModel) -> Promise<Bool> {
        self.globalContext?.loading = true
        
        let promise =
            getConnectionAsync().then({connection in
                Promise<Bool> { resolver in
                    connection.send(command: "CLIENT", with: [RESPValue(from: "KILL"), RESPValue(from: "\(clientModel.addr)")])
                        .whenComplete{ completion in
                            if case .success(let res) = completion {
                                self.logger.info("client kill success: \(res)")
                            
                                resolver.fulfill(true)
                            }
                            else if case .failure(let error) = completion {
                                resolver.reject(error)
                            }
                        }
                }
            })
        
        afterPromise(promise)
        return promise
    }
    
    func clientList() -> Promise<[ClientModel]> {
        self.globalContext?.loading = true
        
        let promise =
            getConnectionAsync().then({connection in
                Promise<[ClientModel]> { resolver in
                    connection.send(command: "CLIENT", with: [RESPValue(from: "LIST")])
                        .whenComplete{ completion in
                            if case .success(let res) = completion {
                                self.logger.info("query redis server client list success: \(res)")
                                let resStr = res.string ?? ""
                                let lines = resStr.components(separatedBy: "\n")

                                var resArray = [ClientModel]()

                                lines.forEach({ line in
                                    if !line.contains("=") {
                                        return
                                    }
                                    resArray.append(ClientModel(line: line))
                                })
                                resolver.fulfill(resArray)
                            }
                            else if case .failure(let error) = completion {
                                resolver.reject(error)
                            }
                        }
                }
            })
        
        afterPromise(promise)
        return promise
    }
    
    func info() -> Promise<[RedisInfoModel]> {
        self.globalContext?.loading = true
        
        let promise =
            getConnectionAsync().then({connection in
                Promise<[RedisInfoModel]> { resolver in
                    connection.send(command: "info")
                        .whenComplete{ completion in
                            if case .success(let res) = completion {
                                self.logger.info("query redis server info success: \(res.string ?? "")")
                                let infoStr = res.string ?? ""
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
                                resolver.fulfill(redisInfoModels)
                            }
                            else if case .failure(let error) = completion {
                                resolver.reject(error)
                            }
                        }
                }
            })
        
        afterPromise(promise)
        return promise
    }
    
    func resetState() -> Promise<Bool> {
        logger.info("reset state...")
        let promise =
            getConnectionAsync().then({ connection in
                Promise<Bool> { resolver in
                    connection.send(command: "CONFIG", with: [RESPValue(from: "RESETSTAT")])
                        .whenComplete({completion in
                            if case .success(let res) = completion {
                                self.logger.info("reset state res: \(res)")
                                resolver.fulfill(res.string == "OK")
                            }
                            else if case .failure(let error) = completion {
                                resolver.reject(error)
                            }
                        })
                }
            })
        
        return promise
    }
    
    private func dbsize() throws -> Int {
        do {
            let res:RESPValue = try getConnection().send(command: "dbsize").wait()
            
            logger.info("query redis dbsize success: \(res.int!)")
            return res.int!
        } catch {
            logger.info("query redis dbsize error: \(error)")
            throw error
        }
    }
    
    func pingAsync() -> Promise<Bool> {
        self.globalContext?.loading = true
        
        let promise =
            getConnectionAsync().then({ connection in
                Promise<Bool> { resolver in
                    connection.ping()
                        .whenComplete({completion in
                            if case .success(let pong) = completion {
                                resolver.fulfill("PONG".caseInsensitiveCompare(pong) == .orderedSame)
                            }
                            else if case .failure(let error) = completion {
                                resolver.reject(error)
                            }
                        })
                }
            })
        
        
        let _ = promise
            .get({ pong in
                DispatchQueue.main.async {
                    self.redisModel.ping = pong
                }
            })
        
        afterPromise(promise)
        
        return promise
    }
    
    func ping() throws -> Bool {
        do {
            let pong = try getConnection().ping().wait()
            
            logger.info("ping redis server: \(pong)")
            
            if ("PONG".caseInsensitiveCompare(pong) == .orderedSame) {
                redisModel.ping = true
                return true
            }
            
            redisModel.ping = false
            return false
        } catch {
            redisModel.ping = false
            logger.error("ping redis server error \(error)")
            throw error
        }
    }
    
}

// config
extension RediStackClient {
    func getConfigList(_ pattern:String = "*") -> Promise<[RedisConfigItemModel]> {
        logger.info("get redis config list, pattern: \(pattern)...")
        globalContext?.loading = true
        
        var _pattern = pattern
        if pattern.isEmpty {
            _pattern = "*"
        }
    
        let promise =
            getConnectionAsync().then({ connection in
                Promise<[RedisConfigItemModel]> { resolver in
                    connection.send(command: "CONFIG", with: [RESPValue(from: "GET"), RESPValue(from: _pattern)])
                        .whenComplete({completion in
                            if case .success(let res) = completion {
                                self.logger.info("get redis config list res: \(res)")
                                
                                let configs = res.array ?? []
                                
                                var configList = [RedisConfigItemModel]()
                                
                                let max:Int = configs.count / 2
                                
                                for index in (0..<max) {
                                    configList.append(RedisConfigItemModel(key: configs[ index * 2].string, value: configs[index * 2 + 1].string))
                                }
                                
                                resolver.fulfill(configList)
                            }
                            else if case .failure(let error) = completion {
                                resolver.reject(error)
                            }
                        })
                }
            })
        
        afterPromise(promise)
        return promise
    }
    
    func configRewrite() -> Promise<Bool> {
        logger.info("redis config rewrite ...")
        globalContext?.loading = true
        
        let promise =
            getConnectionAsync().then({ connection in
                Promise<Bool> { resolver in
                    connection.send(command: "CONFIG", with: [RESPValue(from: "REWRITE")])
                        .whenComplete({completion in
                            if case .success(let res) = completion {
                                self.logger.info("redis config rewrite res: \(res)")
                                resolver.fulfill(res.string == "OK")
                            }
                            else if case .failure(let error) = completion {
                                resolver.reject(error)
                            }
                        })
                }
            })
        
        afterPromise(promise)
        return promise
    }
    
    func getConfigOne(key:String) -> Promise<String?> {
        logger.info("get redis config ...")
        
        let promise =
            getConnectionAsync().then({ connection in
                Promise<String?> { resolver in
                    connection.send(command: "CONFIG", with: [RESPValue(from: "GET"), RESPValue(from: key)])
                        .whenComplete({completion in
                            if case .success(let res) = completion {
                                self.logger.info("get redis config one res: \(res)")
                                resolver.fulfill(res.array?[1].string)
                            }
                            else if case .failure(let error) = completion {
                                resolver.reject(error)
                            }
                        })
                }
            })
        
        return promise
    }
    
    
    func setConfig(key:String, value:String) -> Promise<Bool> {
        logger.info("set redis config, key: \(key), value: \(value)")
        
        let promise =
            getConnectionAsync().then({ connection in
                Promise<Bool> { resolver in
                    connection.send(command: "CONFIG", with: [RESPValue(from: "SET"), RESPValue(from: key), RESPValue(from: value)])
                        .whenComplete({completion in
                            if case .success(let res) = completion {
                                self.logger.info("set config res: \(res)")
                                resolver.fulfill(res.string == "OK")
                            }
                            else if case .failure(let error) = completion {
                                resolver.reject(error)
                            }
                        })
                }
            })
        
        afterPromise(promise)
        return promise
    }
    
}


// slow log
extension RediStackClient {
    func slowLogReset() -> Promise<Bool> {
        logger.info("slow log reset ...")
        let promise =
            getConnectionAsync().then({ connection in
                Promise<Bool> { resolver in
                    connection.send(command: "SLOWLOG", with: [RESPValue(from: "RESET")])
                        .whenComplete({completion in
                            if case .success(let res) = completion {
                                self.logger.info("slow log reset res: \(res)")
                                resolver.fulfill(res.string == "OK")
                            }
                            else if case .failure(let error) = completion {
                                resolver.reject(error)
                            }
                        })
                }
            })
        
        return promise
    }
    
    func slowLogLen() -> Promise<Int> {
        logger.info("get slow log len ...")
        let promise =
            getConnectionAsync().then({ connection in
                Promise<Int> { resolver in
                    connection.send(command: "SLOWLOG", with: [RESPValue(from: "LEN")])
                        .whenComplete({completion in
                            if case .success(let res) = completion {
                                self.logger.info("get slow log len res: \(res)")
                                resolver.fulfill(res.int ?? 0)
                            }
                            else if case .failure(let error) = completion {
                                resolver.reject(error)
                            }
                        })
                }
            })
        
        return promise
    }
    
    func getSlowLog(_ size:Int) -> Promise<[SlowLogModel]> {
        logger.info("get slow log list ...")
        
        self.globalContext?.loading = true
        
        let promise =
            getConnectionAsync().then({ connection in
                Promise<[SlowLogModel]> { resolver in
                    connection.send(command: "SLOWLOG", with: [RESPValue(from: "GET"), RESPValue(from: size)])
                        .whenComplete({completion in
                            // line [110,1626313174,1,[type,NEW_KEY_1626251400704],127.0.0.1:56306,]
                            if case .success(let res) = completion {
                                self.logger.info("get slow log res: \(res)")
                                
                                var slowLogs = [SlowLogModel]()
                                res.array?.forEach({ item in
                                    let itemArray = item.array

                                    let cmd = itemArray?[3].array!.map({
                                        $0.string ?? MTheme.NULL_STRING
                                    }).joined(separator: " ")
                                    
                                    slowLogs.append(SlowLogModel(id: itemArray?[0].string, timestamp: itemArray?[1].int, execTime: itemArray?[2].string, cmd: cmd, client: itemArray?[4].string, clientName: itemArray?[5].string))
                                })
                                
                                resolver.fulfill(slowLogs)
                            }
                            else if case .failure(let error) = completion {
                                resolver.reject(error)
                            }
                        })
                }
            })
       
        afterPromise(promise)
        return promise
    }
}
