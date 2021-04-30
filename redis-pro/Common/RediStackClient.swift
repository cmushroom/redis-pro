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

class RediStackClient{
    var redisModel:RedisModel
    var connection:RedisConnection?
    
    let logger = Logger(label: "redis-client")
    
    init(redisModel:RedisModel) {
        self.redisModel = redisModel
    }
    
    func pageKeys(page:Page, keywords:String?) throws -> [RedisKeyModel] {
        do {
            logger.info("redis keys page scan, page: \(page), keywords: \(String(describing: keywords))")
            
            let match = (keywords == nil || keywords!.isEmpty) ? nil : keywords
            
            var keys:[String] = [String]()
            var cursor:Int = page.cursor
            
            let res:(cursor:Int, keys:[String]) = try scan(cursor:cursor, keywords: match, count: page.size)
            
            keys.append(contentsOf: res.1)
            
            cursor = res.0
            
            // 如果取出数量不够 page.size, 继续迭带补满
            if cursor != 0 && keys.count < page.size {
                while true {
                    let moreRes:(cursor:Int, keys:[String]) = try scan(cursor:cursor, keywords: match, count: 1)
                    
                    keys.append(contentsOf: moreRes.1)
                    
                    cursor = moreRes.0
                    page.cursor = cursor
                    if cursor == 0 || keys.count == page.size {
                        break
                    }
                }
            }
            
            let total = try dbsize()
            page.total = total
            
            return try toRedisKeyModels(keys: keys)
        } catch {
            logger.error("query redis key page error \(error)")
            throw error
        }
    }
    
    
    func pageHashEntry(_ key:String, page:Page) throws -> [String:String?] {
        do {
            logger.info("redis hash field page scan, key: \(key), page: \(page)")
            
            let match = page.keywords.isEmpty ? nil : page.keywords
            
            var entries:[String:String?] = [String:String?]()
            var cursor:Int = page.cursor
            
            let res:(Int, [String:String?]) = try hscan(key, cursor: cursor, count: page.size, keywords: match)
            
            cursor = res.0
            
            entries = res.1
            
            // 如果取出数量不够 page.size, 继续迭带补满
            if cursor != 0 && entries.count < page.size {
                while true {
                    let moreRes:(cursor:Int, [String:String?]) = try hscan(key, cursor:cursor, count: 1, keywords: match)
                    
                    entries = entries.merging(moreRes.1) { (first, _) -> String? in
                        first
                    }
                    
                    cursor = moreRes.0
                    page.cursor = cursor
                    if cursor == 0 || entries.count == page.size {
                        break
                    }
                }
            }
            
            let total = try hlen(key)
            page.total = total
            
            return entries
        } catch {
            logger.error("query redis hash entry page error \(error)")
            throw error
        }
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
    
    func hset(_ key:String, field:String, value:String) throws -> Bool {
        logger.info("redis hash hset key:\(key), field:\(field), value:\(value)")
        return try getConnection().hset(field, to: value, in: RedisKey(key)).wait()
    }
    
    func hdel(_ key:String, field:String) throws -> Int {
        logger.info("redis hash hdel key:\(key), field:\(field)")
        return try getConnection().hdel(field, from: RedisKey(key)).wait()
    }
    
    func hlen(_ key:String) throws -> Int {
        return try getConnection().hlen(of: RedisKey(key)).wait()
    }
    
    func hscan(_ key:String, cursor:Int, count:Int? = 1, keywords:String?) throws -> (Int, [String: String?]) {
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
        return try getConnection().expire(RedisKey(key), after: TimeAmount.seconds(Int64(seconds))).wait()
    }
    
    
    func ttl(key:String) throws -> Int {
        let r:RedisKeyLifetime = try getConnection().ttl(RedisKey(key)).wait()
        
        logger.info("query redis key ttl, key: \(key), r:\(r)")
        if r == RedisKeyLifetime.keyDoesNotExist {
            throw BizError(message: "redis key: \(key) does not exist!")
        } else if r == RedisKeyLifetime.unlimited {
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
    
    
    func scan(cursor:Int, keywords:String?, count:Int? = 1) throws -> (cursor:Int, keys:[String]) {
        do {
            logger.debug("redis keys scan, cursor: \(cursor), keywords: \(String(describing: keywords)), count:\(String(describing: count))")
            return try getConnection().scan(startingFrom: cursor, matching: keywords, count: count).wait()
        } catch {
            logger.error("redis keys scan error \(error)")
            throw error
        }
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
    
    func getConnection() throws -> RedisConnection{
        if connection != nil {
            logger.debug("get redis exist connection...")
            return connection!
        }
        
        logger.debug("start get new redis connection...")
        let eventLoop = MultiThreadedEventLoopGroup(numberOfThreads: 1).next()
        var configuration: RedisConnection.Configuration
        do {
            if (redisModel.password.isEmpty) {
                configuration = try RedisConnection.Configuration(hostname: redisModel.host, port: redisModel.port, initialDatabase: redisModel.database)
            } else {
                configuration = try RedisConnection.Configuration(hostname: redisModel.host, port: redisModel.port, password: redisModel.password, initialDatabase: redisModel.database)
            }
            
            self.connection = try RedisConnection.make(
                configuration: configuration
                , boundEventLoop: eventLoop
            ).wait()
            
            logger.info("get new redis connection success")
            
        } catch {
            logger.error("get new redis connection error \(error)")
            throw error
        }
        
        return connection!
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
}
