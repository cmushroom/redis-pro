//
//  Page.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/13.
//

import Foundation

class Page: CustomStringConvertible, Equatable {
    static func == (lhs: Page, rhs: Page) -> Bool {
        return lhs.current == rhs.current && lhs.size == rhs.size && lhs.keywords == rhs.keywords
    }
    
    var current:Int = 1
    var size:Int = 50
    var total:Int = 0
    var keywords:String = ""
    
    var totalPage:Int {
        get {
            return total < 1 ? 1 : (total % size == 0 ? total / size : total / size + 1)
        }
    }
    
    var start: Int {
        (self.current - 1 ) * self.size
    }
    var end: Int {
        self.current * self.size
    }
    
    var hasPrev:Bool {
        totalPage > 1 && current > 1
    }
    var hasNext:Bool {
        totalPage > 1 && current < totalPage
    }
    
    var description: String {
        return "Page:[current:\(current), size:\(size), total:\(total)]"
    }
    
    
    func reset() {
        self.current = 1
        self.total = 0
    }
    
    func firstPage() {
        self.current = 1
    }
    
    func nextPage() -> Void {
        self.current += 1
    }
    
    func prevPage() -> Void {
        if self.current < 2 {
            return
        }
        self.current -= 1
    }

}
