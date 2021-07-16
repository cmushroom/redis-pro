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
    
    
    func pageKeys(_ page:ScanModel) -> Promise<[RedisKeyModel]> {
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
                                let _ = self.toRedisKeyModels(keys).done({r in
                                    resolver.fulfill(r)
                                })
                                break
                            }
                        }
                    } else {
                        let _ = self.toRedisKeyModels(keys).done({r in
                            resolver.fulfill(r)
                        })
                    }
                    
                }
            })
        
        
        let promise = Promise<[RedisKeyModel]> { resolver in
            let _ = when(fulfilled: dbsizeAsync(),  scanPromise).done({ r1, r2 in
                let total = r1
                page.total = total
                page.cursor = cursor
                
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
    
    // zset operator
    func pageZSet(_ redisKeyModel:RedisKeyModel, page:ScanModel) -> Promise<[RedisZSetItemModel]> {
        if redisKeyModel.isNew {
            return Promise<[RedisZSetItemModel]>.value([RedisZSetItemModel]())
        }
        return pageZSet(redisKeyModel.key, page: page)
    }
    
    func pageZSet(_ key:String, page:ScanModel) -> Promise<[RedisZSetItemModel]> {
        logger.info("redis zset scan page, key: \(key), page: \(page)")
        
        self.globalContext?.loading = true
        let match = page.keywords.isEmpty ? nil : page.keywords
        
        var set:[RedisZSetItemModel] = [RedisZSetItemModel]()
        var cursor:Int = page.cursor
        
        let scanPromise = zscanAsync(key, cursor: cursor, keywords: match).then({ res in
            Promise<[RedisZSetItemModel]>{ resolver in
                cursor = res.0
                let zset = res.1
                
                if zset.count > 0 {
                    zset.forEach({ ele in
                        let item = ele == nil ? RedisZSetItemModel() : RedisZSetItemModel(value: ele!.0, score: "\(ele!.1)")
                        set.append(item)
                    })
                }
                
                // 如果取出数量不够 page.size, 继续迭带补满
                if cursor != 0 && set.count < page.size {
                    while true {
                        let moreRes:(Int, [(String, Double)?]) = try self.zscan(key, cursor:cursor, count: 1, keywords: match)
                        
                        self.logger.info("zset scan more to fill page, res: \(moreRes)")
                        let moreZSet = res.1
                        
                        if moreZSet.count > 0 {
                            moreZSet.forEach({ ele in
                                let item = ele == nil ? RedisZSetItemModel() : RedisZSetItemModel(value: ele!.0, score: "\(ele!.1)")
                                set.append(item)
                            })
                        }
                        
                        cursor = moreRes.0
                        page.cursor = cursor
                        if cursor == 0 || set.count == page.size {
                            resolver.fulfill(set)
                            break
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
        
        
        
        let promise = Promise<[RedisZSetItemModel]> { resolver in
            let _ = when(fulfilled: countPromise,  scanPromise).done({ r1, r2 in
                let total = r1
                page.total = total
                page.cursor = cursor
                
                resolver.fulfill(r2)
            })
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
    func pageSet(_ redisKeyModel:RedisKeyModel, page:ScanModel) -> Promise<[String?]> {
        if redisKeyModel.isNew {
            return Promise<[String?]>.value([String?]())
        }
        return pageSet(redisKeyModel.key, page: page)
    }
    
    func pageSet(_ key:String, page:ScanModel) -> Promise<[String?]> {
        
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
                            break
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
        
        var hashEntryModels = [RedisHashEntryModel]()
        
        var cursor:Int = page.cursor
        
        let scanPromise = hscanAsync(key, cursor: cursor, count: page.size, keywords: match).then({res in
            
            Promise<[RedisHashEntryModel]>{ resolver in
                cursor = res.0
                let dic:[String:String?] = res.1
                if !dic.isEmpty {
                    dic.keys.forEach({key in
                        let value:String? = dic[key] ?? ""
                        hashEntryModels.append(RedisHashEntryModel(field: key, value: value))
                    })
                }
                
                // 如果取出数量不够 page.size, 继续迭带补满
                if cursor != 0 && hashEntryModels.count < page.size {
                    while true {
                        let moreRes:(cursor:Int, [String:String?]) = try self.hscan(key, cursor:cursor, count: 1, keywords: match)
                       
                        let moreDic:[String:String?] = moreRes.1
                        if !moreDic.isEmpty {
                            moreDic.keys.forEach({key in
                                let value:String? = moreDic[key] ?? ""
                                hashEntryModels.append(RedisHashEntryModel(field: key, value: value))
                            })
                        }
                        
                        cursor = moreRes.0
                        page.cursor = cursor
                        if cursor == 0 || hashEntryModels.count == page.size {
                            resolver.fulfill(hashEntryModels)
                            break
                        }
                    }
                } else {
                    resolver.fulfill(hashEntryModels)
                }
            }
        })
        
        let promise = Promise<[RedisHashEntryModel]> { resolver in
            let _ = when(fulfilled: self.hlen(key),  scanPromise).done({ r1, r2 in
                let total = r1
                page.total = total
                page.cursor = cursor
                
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
    
    
    private func dbsizeAsync() -> Promise<Int> {
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
                                        item?.infos.append((infoArr[0].trimmingCharacters(in: .whitespacesAndNewlines), infoArr[1].trimmingCharacters(in: .whitespacesAndNewlines)))
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
    
    func getConnectionAsync() -> Promise<RedisConnection> {
        if self.connection != nil && self.connection!.isConnected{
            self.logger.info("get redis exist connection...")
            return Promise<RedisConnection>.value(self.connection!)
        } else {
            self.close()
        }
        
        return Promise<RedisConnection>{ resolver in
            self.logger.info("start get new redis connection...")
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


// config
extension RediStackClient {
    func getConfigOne(key:String) -> Promise<String?> {
        logger.info("get redis config ...")
        
        let promise =
            getConnectionAsync().then({ connection in
                Promise<String?> { resolver in
                    connection.send(command: "CONFIG", with: [RESPValue(from: "GET"), RESPValue(from: key)])
                        .whenComplete({completion in
                            if case .success(let res) = completion {
                                self.logger.info("get slow log slower than res: \(res)")
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
