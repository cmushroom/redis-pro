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
            
            return try toRedisKeyModels(keys: keys)
        } catch {
            throw BizError.RedisError(message: "\(error)")
        }
    }
    
    func toRedisKeyModels(keys:[String]) throws -> [RedisKeyModel] {
        if keys.isEmpty {
            return [RedisKeyModel]()
        }
        
        var redisKeyModels:[RedisKeyModel] = [RedisKeyModel]()
        
        do {
            
            for key in keys {
                redisKeyModels.append(RedisKeyModel(id: key, type: try type(key: key)))
            }
            
            return redisKeyModels
        } catch {
            logger.error("query redis key  type error \(error)")
            throw BizError.RedisError(message: "query redis key  type error \(error)")
        }
    }
    
    func type(key:String) throws -> String {
        do {
            let res:RESPValue = try getConnection().send(command: "type", with: [RESPValue.init(from: key)]).wait()
            
            return res.string!
        } catch {
            logger.error("query redis key  type error \(error)")
            throw BizError.RedisError(message: "query redis key  type error \(error)")
        }
    }
    
    func scan(cursor:Int, keywords:String?, count:Int? = 1) throws -> (cursor:Int, keys:[String]) {
        do {
            logger.debug("redis keys scan, cursor: \(cursor), keywords: \(String(describing: keywords)), count:\(String(describing: count))")
            return try getConnection().scan(startingFrom: cursor, matching: keywords, count: count).wait()
        } catch {
            logger.error("redis keys scan error \(error)")
            throw BizError.RedisError(message: "redis keys scan error \(error)" )
        }
    }
    
    func dbsize() throws -> Int {
        do {
            let res:RESPValue = try getConnection().send(command: "dbsize").wait()
            
            logger.info("query redis dbsize success: \(res.int!)")
            return res.int!
        } catch {
            logger.info("query redis dbsize error: \(error)")
            throw BizError.RedisError(message: "query redis dbsize error: \(error)")
        }
    }
    
    func ping() throws -> Bool {
        do {
            let pong = try getConnection().ping().wait()
            
            logger.info("ping redis server: \(pong)")
            
            if ("PONG".caseInsensitiveCompare(pong) == .orderedSame) {
                return true
            }
        } catch let error {
            logger.error("ping redis server error \(error)")
            throw BizError.RedisError(message: "ping redis server error \(error)" )
        }
        
        return false
    }
    
    func getConnection() throws -> RedisConnection{
        if connection != nil {
            logger.debug("get redis exist connection...")
            return connection!
        }
        
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
            
            logger.info("get new redis connection success from redis")
            
        } catch let error as RedisError{
            print("connect redis error \(error.message)")
            throw BizError.RedisError(message: error.message)
        }
        
        return connection!
    }
    
    func close() -> Void {
        do {
            if connection == nil {
                logger.info("redis connection is nil, over...")
                return
            }
            
            try connection!.close().wait()
            logger.info("redis connection close success")
            
        } catch {
            logger.error("redis connection close error: \(error)")
        }
    }
}
