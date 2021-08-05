//
//  SSHTunnelTests.swift
//  redisProTests
//
//  Created by chengpanwang on 2021/8/4.
//

import XCTest
import NIOSSH
import NIO
import RediStack
@testable import redis_pro

class SSHTunnelTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testSSHConnection() -> Void {
        let redisModel = RedisModel()

        
        let redisInstance = RedisInstanceModel(redisModel: redisModel)
        let _ = redisInstance.getClient().getSSHConnection().done { connection in
            connection.ping().whenSuccess { r in
                print("ping: \(r)")
            }
        }
        sleep(5)
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
