//
//  RedisInsanceModel.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/1/25.
//

import SwiftUI
import Foundation
import NIO
import RediStack
import Logging


class RedisInstanceModel:ObservableObject, Identifiable {
    @Published var loading:Bool = false
    var redisModel:RedisModel
    
    var image: Image {
        Image("icon-redis")
    }
    
    let logger = Logger(label: "RedisInstanceModel")
    
    init(redisModel: RedisModel) {
        self.redisModel = redisModel
        print("redis instance model init")
    }
    
    func getConnection() throws -> RedisConnection?{
        let eventLoop = MultiThreadedEventLoopGroup(numberOfThreads: 1).next()
        var connection: RedisConnection?
        var configuration: RedisConnection.Configuration
        do {
            if (redisModel.password.isEmpty) {
                configuration = try RedisConnection.Configuration(hostname: redisModel.host, port: redisModel.port, initialDatabase: redisModel.database)
            } else {
                configuration = try RedisConnection.Configuration(hostname: redisModel.host, port: redisModel.port, password: redisModel.password, initialDatabase: redisModel.database)
            }
            
            connection = try RedisConnection.make(
                configuration: configuration
                , boundEventLoop: eventLoop
            ).wait()
            
            logger.info("get connection from redis")
        } catch let error as RedisError{
            print("connect redis error \(error.message)")
            throw BizError.RedisError(message: error.message)
        }
        return connection
    }
    
    
    func ping() throws -> Bool{
        do {
            self.loading = true
            let connection: RedisConnection? = try getConnection();
            
            defer {
                logger.info("close connection after redis ping")
                self.loading = false
                connection?.close()
            }
            
            if (connection == nil) {
                return false
            }
            
            let pong = try connection!.ping().wait()
            
            print("ping redis r: \(pong)")
            if ("PONG".caseInsensitiveCompare(pong) == .orderedSame) {
                return true
            }
        } catch {
            print("connect redis error \(error)")
            throw error
        }
        
        return false
    }
}
