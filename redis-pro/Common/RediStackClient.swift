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
    
    func scan(page:Page, keywords:String) throws -> (cursor:Int, keys:[String]) {
        return try getConnection().scan(startingFrom: page.start, matching: keywords, count: page.size).wait()
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
            
            logger.info("get connection success from redis")
            
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
            
            try connection!.close()
            logger.info("redis connection close success")
            
        } catch {
            logger.error("redis connection close error: \(error)")
        }
    }
}
