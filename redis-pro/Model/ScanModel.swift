//
//  ScanModel.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/6/1.
//

import Foundation
import Logging

class ScanModel:ObservableObject, CustomStringConvertible {
    var current:Int = 1
    @Published var total:Int = 0
    @Published var cursor:Int = 0
    @Published var size:Int = 50
    @Published var keywords:String = ""
    private var cursorHistory:[Int] = [0]
    
    let logger = Logger(label: "scan-model")
    
    var hasNext:Bool {
        self.cursor != 0
    }
    
    var hasPrev:Bool {
        self.cursorHistory.count > 1
    }
    
    
    var description: String {
        return "ScanModel:[cursor:\(cursor), size:\(size), keywords:\(keywords), history: \(cursorHistory)]"
    }
    
    func resetHead() -> Void {
        self.cursor = 0
        self.cursorHistory = [0]
    }
    
    func notifyNextPage() -> Void {
        if self.cursor == 0 {
            return
        }
        self.cursorHistory.append(self.cursor)
        self.current += 1
        logger.info("scan model notify next page \(self)")
    }
    
    // 0 - 18 - 5
    func prevPage() -> Void {
        if !hasPrev {
            return
        }
        
        logger.info("scan model prev page \(self.cursorHistory)")
        self.current -= 1
        self.cursor = self.cursorHistory.popLast() ?? 0
    }
}
