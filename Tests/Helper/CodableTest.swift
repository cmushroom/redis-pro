//
//  JSONHelperTest.swift
//  Tests
//
//  Created by chengpan on 2024/1/28.
//


@testable import redis_pro
import XCTest

final class CodableTest: RedisClientBaseTest {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testParse() throws {
        
        let text = #"{"latestVersionNum": 1, "latestVersion": null}"#
        let v = try JSONDecoder().decode(VersionModel.self, from: text.data(using: .utf8)!)
        
        print("test parse: \(v)")
    }

}
