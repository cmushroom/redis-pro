//
//  JsonPrettyFormatTests.swift
//  redisProTests
//
//  Created by chengpanwang on 2021/6/1.
//

import Foundation
import XCTest
import SwiftyJSON

class JsonPrettyFormatTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testPrettyFormat() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        print("pretty format json")
        let json:String = """
            {"a": 1, "b": "test", "arr": 1, 2 ,3]}
            """
        let jsonObj = JSON(parseJSON: json)
        print("parse json \(jsonObj)")
        
        print("type of jsonObj \(jsonObj == JSON.null)")
        
        if let string = jsonObj.rawString() {
            print("json \(string)")
        }
//        print(String(data: try! JSONSerialization.data(withJSONObject: jsonObj, options: .prettyPrinted), encoding: .utf8)!)

    }
    
    func testPopLast() -> Void {
        var arr:[Int] = [1,2,3,4,5]
        print(arr.popLast() ?? 0)
        print(arr.popLast() ?? 0)
        print(arr.popLast() ?? 0)
        print(arr.popLast() ?? 0)
        print(arr.count)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
