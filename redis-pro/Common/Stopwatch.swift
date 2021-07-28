//
//  Stopwatch.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/7/28.
//

import Foundation

struct Stopwatch {
    private var start:Int64 = 0
    
    init() {
        let timeInterval: TimeInterval = Date().timeIntervalSince1970
        start = CLongLong(round(timeInterval*1000))
    }
    
    static func createStarted() -> Stopwatch {
        return Stopwatch()
    }
    
    func elapsedMillis() -> Int64 {
        let timeInterval: TimeInterval = Date().timeIntervalSince1970
        return CLongLong(round(timeInterval * 1000)) - self.start
    }
}
