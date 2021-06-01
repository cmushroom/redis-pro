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
    
    
    func pageKeys(page:Page) -> Promise<[RedisKeyModel]> {
        self.globalContext?.loading = true
        
        logger.info("redis keys page scan, page: \(page)")
        
        let match = page.keywords.isEmpty ? nil : page.keywords
        
        var keys:[String] = [String]()
        var cursor:Int = page.cursor
        
        let scanPromise = scanAsync(cursor:cursor, keywords: match, count: page.size)
            .then({ res in
                Promise<[RedisKeyModel]> { resolver in
                    keys.append(contentsOf: res.1)
                    cursor = res.0
                    
                    // 如果取出数量不够 page.size, 继续迭带补满
                    if cursor != 0 && keys.count < page.size {
                        while true {
                            let moreRes = try self.scan(cursor:cursor, keywords: match, count: 1)
                            keys.append(contentsOf: moreRes.1)
                            cursor = moreRes.0
                            if cursor == 0 || keys.count == page.size {
                                resolver.fulfill(try self.toRedisKeyModels(keys: keys))
                            }
                        }
                    } else {
                        resolver.fulfill(try self.toRedisKeyModels(keys: keys))
                    }
                    
                }
            })
        
        
        let promise = Promise<[RedisKeyModel]> { resolver in
            let _ = when(fulfilled: dbsizeAsync(),  scanPromise).done({ r1, r2 in
                print("when result.... \(r1), \(r2)")
                let total = r1
                page.total = total
                page.hasNext = cursor != 0
                page.cursor = cursor
                
                resolver.fulfill(r2)
            })
        }
        afterPromise(promise)
        return promise
    }
    
    func toRedisKeyModels(keys:[String]) throws -> [RedisKeyModel] {
        if keys.isEmpty {
            return [RedisKeyModel]()
        }
        
        var redisKeyModels:[RedisKeyModel] = [RedisKeyModel]()
        
        do {
            
            for key in keys {
                redisKeyModels.append(RedisKeyModel(key: key, type: try type(key: key)))
            }
            
            return redisKeyModels
        } catch {
            logger.error("query redis key  type error \(error)")
            throw error
        }
    }
    
    // zset operator
    func pageZSet(_ redisKeyModel:RedisKeyModel, page:Page) -> Promise<[(String, Double)?]> {
        if redisKeyModel.isNew {
            return Promise<[(String, Double)?]>.value([(String, Double)?]())
        }
        return pageZSet(redisKeyModel.key, page: page)
    }
    
    func pageZSet(_ key:String, page:Page) -> Promise<[(String, Double)?]> {
        logger.info("redis set page, key: \(key), page: \(page)")
        
        self.globalContext?.loading = true
        let match = page.keywords.isEmpty ? nil : page.keywords
        
        var set:[(String, Double)?] = [(String, Double)?]()
        var cursor:Int = page.cursor
        
        let scanPromise = zscanAsync(key, cursor: cursor, keywords: match).then({ res in
            Promise<[(String, Double)?]>{ resolver in
                cursor = res.0
                set = res.1
                
                // 如果取出数量不够 page.size, 继续迭带补满
                if cursor != 0 && set.count < page.size {
                    while true {
                        let moreRes:(Int, [(String, Double)?]) = try self.zscan(key, cursor:cursor, count: 1, keywords: match)
                        
                        set.append(contentsOf: moreRes.1)
                        cursor = moreRes.0
                        page.cursor = cursor
                        if cursor == 0 || set.count == page.size {
                            resolver.fulfill(set)
                        }
                    }
                } else {
                    resolver.fulfill(set)
                }
            }
        })
        
        
        let countPromise =
            getConnectionAsync().then({ connection in
                Promise<Int> { resolver in
                    connection.zcard(of: RedisKey(key))
                        .whenComplete({ completion in
                            if case .success(let r) = completion {
                                resolver.fulfill(r)
                            }
                            else if case .failure(let error) = completion {
                                self.logger.error("redis zset zcard key:\(key) error: \(error)")
                                resolver.reject(error)
                            }
                        })
                }
            })
        
        
        
        let promise = Promise<[(String, Double)?]> { resolver in
            let _ = when(fulfilled: countPromise,  scanPromise).done({ r1, r2 in
                let total = r1
                page.total = total
                page.hasNext = cursor != 0
                page.cursor = cursor
                
                resolver.fulfill(r2)
            }).catch({ error in
                self.globalContext?.showError(error)
            }).finally {
                DispatchQueue.main.async {
                    self.globalContext?.loading =  false
                }
            }
        }
        afterPromise(promise)
        return promise
    }
    
    
    func zscanAsync(_ key:String, cursor:Int, count:Int? = 1, keywords:String?) -> Promise<(Int, [(String, Double)?])> {
        
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
                            self.logger.error("redis zset zcard key:\(key) error: \(error)")
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
    
    // set operator
    func pageSet(_ redisKeyModel:RedisKeyModel, page:Page) -> Promise<[String?]> {
        if redisKeyModel.isNew {
            return Promise<[String?]>.value([String?]())
        }
        return pageSet(redisKeyModel.key, page: page)
    }
    
    func pageSet(_ key:String, page:Page) -> Promise<[String?]> {
        
        logger.info("redis set page, key: \(key), page: \(page)")
        
        self.globalContext?.loading = true
        
        let match = page.keywords.isEmpty ? nil : page.keywords
        
        var set:[String?] = [String?]()
        var cursor:Int = page.cursor
        
        let scanPromise = sscanAsync(key, cursor: cursor, count: page.size, keywords: match).then({ res in
            Promise<[String?]>{ resolver in
                cursor = res.0
                set = res.1
                
                
                // 如果取出数量不够 page.size, 继续迭带补满
                if cursor != 0 && set.count < page.size {
                    while true {
                        let moreRes:(Int, [String?]) = try self.sscan(key, cursor:cursor, count: 1, keywords: match)
                        
                        set.append(contentsOf: moreRes.1)
                        cursor = moreRes.0
                        page.cursor = cursor
                        if cursor == 0 || set.count == page.size {
                            resolver.fulfill(set)
                        }
                    }
                } else {
                    resolver.fulfill(set)
                }
            }
        })
        
        
        let countPromise =
            getConnectionAsync().then({ connection in
                Promise<Int> { resolver in
                    connection.scard(of: RedisKey(key))
                        .whenComplete({ completion in
                            if case .success(let r) = completion {
                                resolver.fulfill(r)
                            }
                            else if case .failure(let error) = completion {
                                self.logger.error("redis set card key:\(key) error: \(error)")
                                resolver.reject(error)
                            }
                        })
                }
            })
        
        
        
        let promise = Promise<[String?]> { resolver in
            let _ = when(fulfilled: countPromise,  scanPromise).done({ r1, r2 in
                let total = r1
                page.total = total
                page.hasNext = cursor != 0
                page.cursor = cursor
                
                resolver.fulfill(r2)
            })
        }
        afterPromise(promise)
        return promise
    }
    
    func sscanAsync(_ key:String, cursor:Int, count:Int? = 1, keywords:String?) -> Promise<(Int, [String?])> {
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
        
        //        return try getConnection().srem(ele, from: RedisKey(key)).wait()
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
    
    // list operator
    func pageList(_ redisKeyModel:RedisKeyModel, page:Page) throws -> [String?] {
        if redisKeyModel.isNew {
            return [String?]()
        }
        return try pageList(redisKeyModel.key, page: page)
    }
    
    func pageList(_ key:String, page:Page) throws -> [String?] {
        
        do {
            logger.info("redis list page, key: \(key), page: \(page)")
            
            let cursor:Int = (page.current - 1) * page.size
            
            let total = try llen(key)
            page.total = total
            
            return try lrange(key, start: cursor, stop: cursor + page.size - 1)
            
        } catch {
            logger.error("query redis list page error \(error)")
            throw error
        }
    }
    
    func lrange(_ key:String, start:Int, stop:Int) throws -> [String?] {
        do {
            logger.debug("redis list range, key: \(key)")
            
            return try getConnection().lrange(from: RedisKey(key), firstIndex: start, lastIndex: stop, as: String.self).wait()
            
        } catch {
            logger.error("redis list range key:\(key) error: \(error)")
            throw error
        }
    }
    
    
    func lrem(_ key:String, value:String) throws -> Int {
        do {
            logger.debug("redis list lrem, key: \(key)")
            
            return try getConnection().lrem(value, from: RedisKey(key), count: 1).wait()
            
        } catch {
            logger.error("redis list lrem key:\(key) error: \(error)")
            throw error
        }
    }
    
    
    func ldel(_ key:String, index:Int) throws -> Int {
        do {
            logger.debug("redis list delete, key: \(key), index:\(index)")
            
            try lset(key, index: index, value: Constants.LIST_VALUE_DELETE_MARK)
            
            return try getConnection().lrem(Constants.LIST_VALUE_DELETE_MARK, from: RedisKey(key), count: 0).wait()
            
        } catch {
            logger.error("redis list lrem key:\(key) error: \(error)")
            throw error
        }
    }
    
    func lset(_ key:String, index:Int, value:String) throws -> Void {
        try getConnection().lset(index: index, to: value, in: RedisKey(key)).wait()
    }
    
    func lpush(_ key:String, value:String) throws -> Int {
        return try getConnection().lpush(value, into: RedisKey(key)).wait()
    }
    
    func rpush(_ key:String, value:String) throws -> Int {
        return try getConnection().rpush(value, into: RedisKey(key)).wait()
    }
    
    func llen(_ key:String) throws -> Int {
        do {
            logger.debug("redis list length, key: \(key)")
            
            return try getConnection().llen(of: RedisKey(key)).wait()
            
        } catch {
            logger.error("redis list length key:\(key) error: \(error)")
            throw error
        }
    }
    
    
    // hash operator
    
    func pageHash(_ redisKeyModel:RedisKeyModel, page:Page) -> Promise<[String:String?]> {
        if redisKeyModel.isNew {
            return Promise<[String:String?]>.value([String:String?]())
        }
        
        return pageHash(redisKeyModel.key, page: page)
    }
    
    func pageHash(_ key:String, page:Page) -> Promise<[String:String?]> {
        logger.info("redis hash field page scan, key: \(key), page: \(page)")
        
        self.globalContext?.loading = true
        
        let match = page.keywords.isEmpty ? nil : page.keywords
        
        var entries:[String:String?] = [String:String?]()
        var cursor:Int = page.cursor
        
        let scanPromise = hscanAsync(key, cursor: cursor, count: page.size, keywords: match).then({res in
            
            Promise<[String:String?]>{ resolver in
                cursor = res.0
                entries = res.1
                
                // 如果取出数量不够 page.size, 继续迭带补满
                if cursor != 0 && entries.count < page.size {
                    while true {
                        let moreRes:(cursor:Int, [String:String?]) = try self.hscan(key, cursor:cursor, count: 1, keywords: match)
                        
                        entries = entries.merging(moreRes.1) { (first, _) -> String? in
                            first
                        }
                        
                        cursor = moreRes.0
                        page.cursor = cursor
                        if cursor == 0 || entries.count == page.size {
                            resolver.fulfill(entries)
                        }
                    }
                } else {
                    resolver.fulfill(entries)
                }
            }
        })
        
        let promise = Promise<[String:String?]> { resolver in
            let _ = when(fulfilled: self.hlen(key),  scanPromise).done({ r1, r2 in
                let total = r1
                page.total = total
                page.hasNext = cursor != 0
                page.cursor = cursor
                
                resolver.fulfill(r2)
            })
        }
        afterPromise(promise)
        return promise
        
        //        do {
        //            logger.info("redis hash field page scan, key: \(key), page: \(page)")
        //
        //            let match = page.keywords.isEmpty ? nil : page.keywords
        //
        //            var entries:[String:String?] = [String:String?]()
        //            var cursor:Int = page.cursor
        //
        //            let res:(Int, [String:String?]) = try hscan(key, cursor: cursor, count: page.size, keywords: match)
        //
        //            cursor = res.0
        //
        //            entries = res.1
        //
        //            // 如果取出数量不够 page.size, 继续迭带补满
        //            if cursor != 0 && entries.count < page.size {
        //                while true {
        //                    let moreRes:(cursor:Int, [String:String?]) = try hscan(key, cursor:cursor, count: 1, keywords: match)
        //
        //                    entries = entries.merging(moreRes.1) { (first, _) -> String? in
        //                        first
        //                    }
        //
        //                    cursor = moreRes.0
        //                    page.cursor = cursor
        //                    if cursor == 0 || entries.count == page.size {
        //                        break
        //                    }
        //                }
        //            }
        //
        //            let total = try hlen(key)
        //            page.total = total
        //            page.hasNext = cursor != 0
        //            page.cursor = cursor
        //
        //            return entries
        //        } catch {
        //            logger.error("query redis hash entry page error \(error)")
        //            throw error
        //        }
    }
    
    func hset(_ key:String, field:String, value:String) throws -> Bool {
        logger.info("redis hash hset key:\(key), field:\(field), value:\(value)")
        return try getConnection().hset(field, to: value, in: RedisKey(key)).wait()
    }
    
    func hdel(_ key:String, field:String) throws -> Int {
        logger.info("redis hash hdel key:\(key), field:\(field)")
        return try getConnection().hdel(field, from: RedisKey(key)).wait()
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
    
    private func hscanAsync(_ key:String, cursor:Int, count:Int? = 1, keywords:String?) -> Promise<(Int, [String: String?])> {
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
    
    func hget(_ key:String, field:String) throws -> String {
        do {
            let v = try getConnection().hget(field, from: RedisKey(key)).wait()
            logger.info("hget value key: \(key), field: \(field) complete, r: \(v)")
            
            if v.isNull {
                throw BizError(message: "Key `\(key)`, field: `\(field)` is not exist!")
            }
            return v.string!
        } catch {
            logger.error("get value key:\(key) error: \(error)")
            throw error
        }
    }
    
    // string operator
    
    func set(_ key:String, value:String, ex:Int?) throws -> Void {
        logger.info("set value, key:\(key), value:\(value), ex:\(ex ?? -1)")
        if (ex == nil || ex! == -1) {
            try getConnection().set(RedisKey(key), to: value).wait()
        } else {
            try getConnection().setex(RedisKey(key), to: value, expirationInSeconds: ex!).wait()
        }
    }
    
    func get(key:String) throws -> String {
        do {
            let v = try getConnection().get(RedisKey(key)).wait()
            logger.info("get value key: \(key) complete, r: \(v)")
            
            if v.isNull {
                throw BizError(message: "Key `\(key)` is not exist!")
            }
            return v.string!
        } catch {
            logger.error("get value key:\(key) error: \(error)")
            throw error
        }
    }
    
    
    func del(key:String) throws -> Int {
        do {
            let count:Int = try getConnection().delete(RedisKey(key)).wait()
            logger.info("delete redis key \(key) complete, r: \(count)")
            return count
        } catch {
            logger.error("delete redis key:\(key) error: \(error)")
            throw error
        }
    }
    
    
    
    func expire(_ key:String, seconds:Int) throws -> Bool {
        logger.info("set key expire key:\(key), seconds:\(seconds)")
        if seconds < 0 {
            let _ = try getConnection().send(command: "PERSIST", with: [RESPValue(from: key)]).wait()
            return  true
        } else {
            return try getConnection().expire(RedisKey(key), after: TimeAmount.seconds(Int64(seconds))).wait()
        }
    }
    
    func ttl(_ redisKeyModel:RedisKeyModel) throws -> Void {
        if redisKeyModel.isNew {
            return
        }
        try redisKeyModel.ttl = ttl(key: redisKeyModel.key)
    }
    
    
    func ttl(key:String) throws -> Int {
        let r:RedisKey.Lifetime = try getConnection().ttl(RedisKey(key)).wait()
        
        logger.info("query redis key ttl, key: \(key), r:\(r)")
        if r == RedisKey.Lifetime.keyDoesNotExist {
            throw BizError(message: "redis key: \(key) does not exist!")
        } else if r == RedisKey.Lifetime.unlimited {
            return -1
        } else {
            return Int(r.timeAmount!.nanoseconds / 1000000000)
        }
    }
    
    func type(key:String) throws -> String {
        do {
            let res:RESPValue = try getConnection().send(command: "type", with: [RESPValue.init(from: key)]).wait()
            
            return res.string!
        } catch {
            logger.error("query redis key  type error \(error)")
            throw error
        }
    }
    
    func scanAsync(cursor:Int, keywords:String?, count:Int? = 1) -> Promise<(cursor:Int, keys:[String])> {
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
    
    
    func scan(cursor:Int, keywords:String?, count:Int? = 1) throws -> (cursor:Int, keys:[String]) {
        logger.debug("redis keys scan, cursor: \(cursor), keywords: \(String(describing: keywords)), count:\(String(describing: count))")
        
        return try getConnection().scan(startingFrom: cursor, matching: keywords, count: count).wait()
    }
    
    func rename(_ oldKey:String, newKey:String) throws -> Bool {
        let res:RESPValue = try getConnection().send(command: "RENAME", with: [RESPValue(from: oldKey), RESPValue(from: newKey)]).wait()
        logger.info("rename key, old key:\(oldKey), new key: \(newKey)")
        return res.string == "OK"
    }
    
    func selectDB(_ database: Int) throws -> Void {
        try getConnection().select(database: database).wait()
        logger.info("select redis database: \(database)")
    }
    
    func databases() throws -> Int {
        let res:RESPValue = try getConnection().send(command: "CONFIG", with: [RESPValue(from: "GET"), RESPValue(from: "databases")]).wait()
        let dbs = res.array
        logger.info("get config databases: \(String(describing: dbs))")
        
        return NumberHelper.toInt(dbs?[1], defaultValue: 16)
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
    
    func dbsize() throws -> Int {
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
    
    func getConnectionAsync() -> Promise<RedisConnection> {
        return Promise<RedisConnection>{ resolver in
            if self.connection != nil && self.connection!.isConnected{
                self.logger.debug("get redis exist connection...")
                resolver.fulfill(self.connection!)
            } else {
                self.close()
            }
            
            self.logger.debug("start get new redis connection...")
            let eventLoop = MultiThreadedEventLoopGroup(numberOfThreads: 1).next()
            var configuration: RedisConnection.Configuration
            do {
                if (self.redisModel.password.isEmpty) {
                    configuration = try RedisConnection.Configuration(hostname: self.redisModel.host, port: self.redisModel.port, initialDatabase: self.redisModel.database)
                } else {
                    configuration = try RedisConnection.Configuration(hostname: self.redisModel.host, port: self.redisModel.port, password: self.redisModel.password, initialDatabase: self.redisModel.database)
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
        do {
            if connection == nil {
                logger.info("close redis connection, connection is nil, over...")
                return
            }
            
            try connection!.close().wait()
            connection = nil
            logger.info("redis connection close success")
            
        } catch {
            logger.error("redis connection close error: \(error)")
        }
    }
    
    func afterPromise<T:CatchMixin>(_ promise:T) -> Void{
        promise
            .catch({error in
                self.globalContext?.showError(error)
            })
            .finally {
                self.globalContext?.loading = false
            }
    }
}
