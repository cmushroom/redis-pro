//
//  RedisClent.swift
//  Tests
//
//  Created by chengpan on 2022/12/3.
//

@testable import redis_pro
import XCTest
import Foundation

class RedisClentStringTest: RedisClientBaseTest {
    let key = "redis_client_test_key"
    let value = "redis_client_test_value"
    
    func testSetKey() async {
        await redisClient.set(key, value: value)
    }
    
    func testGetKey() async {
        await testSetKey()
        let r = await redisClient.get(key)
        
        logger.info("redis client test get key, r: \(r)")
        XCTAssertEqual(value, r)
    }
}
