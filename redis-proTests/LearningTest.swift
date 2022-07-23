//
//  LearningTest.swift
//  redis-proTests
//
//  Created by chengpan on 2022/4/30.
//

import XCTest
@testable import redis_pro

class LearningTest: XCTestCase {

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
//        let l1 = [RedisModel(name: "1")]
//        let l2 = [l1[0], l1[0]]
//
//        let b = l1 == l2
//        print("equals: \(b)")
        
        var lua = "Eval 'hello' 2 arg1 arg2 arv1 arv2"
        print("\(StringHelper.removeStartIgnoreCase(lua, start: "eval"))")
        
        lua = StringHelper.trim(StringHelper.removeStartIgnoreCase(lua, start: "eval"))
        if !StringHelper.startWith(lua, start: "'") && !StringHelper.startWith(lua, start: "\"") {
            throw BizError("lua script syntax error, demo: \"return {KEYS[1],KEYS[2],ARGV[1],ARGV[2]}\" 2 key1 key2 arg1 arg2")
        }
        
        let separator = lua[0]
        let scriptLastIndex = lua.lastIndexOf(separator)!
        let start = lua.index(lua.startIndex, offsetBy: 1)
        let script = String(lua[start..<scriptLastIndex])
        
        let argStart = lua.index(scriptLastIndex, offsetBy: 1)
        let args = StringHelper.trim(String(lua[argStart...]))
        
        let argArr = StringHelper.split(args)
        
        print("\(separator), \(script), \(args), \(argArr)")
        
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
