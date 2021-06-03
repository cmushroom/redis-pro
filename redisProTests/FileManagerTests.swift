//
//  FileManagerTests.swift
//  redisProTests
//
//  Created by chengpanwang on 2021/6/2.
//

import XCTest

class FileManagerTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let url = URL(fileURLWithPath: "Logs")
        let f = try! FileManager.default.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: url, create: true)
        print("log dir \(f.path)")
        let fileURL = f.appendingPathComponent("Logs", isDirectory: true).appendingPathComponent("redis-pro").appendingPathExtension("log")
        
//        let writeText = "log to file...12321312323"
//        try writeText.write(to: fileURL, atomically: true, encoding: String.Encoding.utf8)
        print("log file \(fileURL.path)")
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
