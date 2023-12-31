//
//  StoreBaseTests.swift
//  Tests
//
//  Created by chengpan on 2023/8/5.
//

@testable import redis_pro
import Foundation
import Logging
import XCTest
import ComposableArchitecture


class StoreBaseTests: RedisClientBaseTest {
    var redisInstance: RedisInstanceModel!
    
    override func setUp() {
        super.setUp()
        self.redisInstance = RedisInstanceModel(redisModel: redisModel)

        logger.info("StoreBaseTests setup...")
    }
    
    
    func testExample() {
        logger.info("test example ...")
    }
}
