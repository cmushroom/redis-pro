//
//  ScanModel.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/6/1.
//

import Foundation
import Logging

class ScanModel:ObservableObject, CustomStringConvertible, Equatable {
    static func == (lhs: ScanModel, rhs: ScanModel) -> Bool {
        return lhs.cursor == rhs.cursor && lhs.size == rhs.size && lhs.keywords == rhs.keywords
    }
    
    var current:Int = 1
    @Published var total:Int = 0
    @Published var cursor:Int = 0
    @Published var size:Int = 50
    @Published var keywords:String = ""
    private var cursorHistory:[Int] = [Int]()
    
    let logger = Logger(label: "scan-model")
    
    var totalPage:Int {
        if total <= 0 {
            return 1
        }
        
        if total % size == 0 {
            return total / size
        } else {
            return total / size + 1
        }
    }
    
    var hasNext:Bool {
        self.cursor != 0
//        self.current < totalPage
    }
    
    var hasPrev:Bool {
        self.cursorHistory.count > 0
//        self.current > 1
    }
    
    
    var description: String {
        return "ScanModel:[cursor:\(cursor), size:\(size), keywords:\(keywords), history: \(cursorHistory), current: \(current)]"
    }
    
    func reset() -> Void {
        self.current = 1
        self.cursor = 0
        self.cursorHistory.removeAll()
    }
    
    func nextPage() -> Void {
        self.current += 1
        self.cursorHistory.append(self.cursor)
    }
    
    func prevPage() -> Void {
        self.current -= 1
//
        if self.current <= 1 {
            self.current = 1
            self.cursor = 0
            cursorHistory.removeAll()
        }

        let index = self.current - 1
        self.cursor = (index == 0 || cursorHistory.count == 0) ? 0 : cursorHistory[index - 1]
        self.cursorHistory.removeSubrange(index...)
    }
}
