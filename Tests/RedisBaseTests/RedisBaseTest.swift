//
//  RedisClientBaseTest.swift
//  Tests
//
//  Created by chengpan on 2022/12/3.
//

import XCTest

open class RedisBaseTest: XCTestCase {
    open var redisHostname: String {
        return ProcessInfo.processInfo.environment["REDIS_HOST"] ?? "localhost"
    }
    
    open var redisPort: Int {
        return Int(ProcessInfo.processInfo.environment["REDIS_PORT"] ?? "6379")!
    }
    
    open var redisUsername: String? {
        return ProcessInfo.processInfo.environment["REDIS_USERNAME"]
    }
    
    open var redisPassword: String? {
        return ProcessInfo.processInfo.environment["REDIS_PW"]
    }
}
