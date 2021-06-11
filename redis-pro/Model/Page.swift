//
//  Page.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/13.
//

import Foundation

class Page:ObservableObject, CustomStringConvertible {
    @Published var current:Int = 1
    @Published var size:Int = 50
    @Published var total:Int = 0
    @Published var keywords:String = ""
    private var cursorHistory:[Int] = [Int]()
    
    var totalPage:Int {
        get {
            return total < 1 ? 1 : (total % size == 0 ? total / size : total / size + 1)
        }
    }
    
    var hasPrevPage:Bool {
        totalPage > 1 && current > 1
    }
    var hasNextPage:Bool {
        totalPage > 1 && current < totalPage
    }
    
    var description: String {
        return "Page:[current:\(current), size:\(size), total:\(total)]"
    }
    
    
    func reset() {
        self.current = 1
        self.keywords = ""
    }
    
    func firstPage() {
        self.current = 1
    }
    
    func nextPage() -> Void {
        self.current += 1
    }
    
    
    // 0 - 18 - 5
    func prevPage() -> Void {
        self.current -= 1
        if self.current <= 1 {
            self.current = 1
        }
    }
}
