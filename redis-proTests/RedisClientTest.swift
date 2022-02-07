//
//  RedisClientTest.swift
//  redis-proTests
//
//  Created by chengpan on 2022/2/7.
//

import XCTest
@testable import redis_pro

class RedisClientTest: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
        
        let redisModel = RedisModel()
        redisModel.host = "101.35.200.189"
        redisModel.port = 11379
        redisModel.password = "zaqwedxRTY123456"
        redisModel.database = 0
        
        let redisInstance = RedisInstanceModel(redisModel: redisModel)
        
        Task {
            let _ = await redisInstance.connect(redisModel: redisModel)
            
            for index in 1...10000 {
//                let _ = await redisInstance.getClient().hset("hash_perf", field: "k_\(index)", value: "\(index)")
                let _ = await redisInstance.getClient().zadd("zset_perf", score: Double(index), ele: "e_\(index)")
            }
        }
        
        sleep(1000000)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
