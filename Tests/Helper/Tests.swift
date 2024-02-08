//
//  Tests.swift
//  Tests
//
//  Created by chengpan on 2022/12/3.
//

import XCTest

final class Tests: XCTestCase {

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
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }
    
//    func testJson() {
//        let text = "{\"latestVersionNum\": 1}"
//        
//        let data = Data(text.utf8)
//        do {
//           // make sure this JSON is in the format we expect
//           if let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
//               let latestVersionNum = dictionary["latestVersionNum"]
//              print("Dictionary format: \(dictionary), \(latestVersionNum)")
//               let b = Int("\(latestVersionNum)") ?? 0
//               print("\(b > 0)")
//           }
//        } catch let error as NSError {
//           print("Failed to load: \(error.localizedDescription)")
//        }
        
//        try JSONDecoder().decode(VersionModel.self, from: text.data(using: .utf8)!)
//        
//    }

}
