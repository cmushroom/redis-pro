//
//  RedisClientBaseTests.swift
//  Tests
//
//  Created by chengpan on 2022/12/3.
//

@testable import redis_pro
import XCTest
import Foundation
import Logging

open class RedisClientBaseTest: RedisBaseTest {
    let logger = Logger(label: "redis-client-test")
    
    var redisClient: RediStackClient!
    
    open override func setUp() {
        logger.info("redis client base test setUp...")
        redisClient = .init(RedisModel(host: redisHostname, port: redisPort, username: redisUsername, password: redisPassword))
//            let conn = try await redisClient.initConn(host: redisHostname, port: redisPort, username: redisUsername ?? "", pass: redisPassword ?? "", database: 0)
    }
    
    /// Sends a "FLUSHALL" command to Redis to clear it of any data from the previous test, then closes the connection.
    ///
    /// If any steps fail, a `fatalError` is thrown.
    ///
    /// See `XCTest.XCTestCase.tearDown()`
    open override func tearDown() {
//        Task {
//            await redisClient.flushDB()
//        }
        
        redisClient.close()
    }
}
