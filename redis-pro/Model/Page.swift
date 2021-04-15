//
//  Page.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/13.
//

import Foundation

class Page:ObservableObject, CustomStringConvertible {
    var cursor:Int = 0
    @Published var current:Int = 1
    @Published var size:Int = 50
    @Published var total:Int = 0
    
    var totalPage:Int {
        total < 1 ? 0 : (total % size == 0 ? total / size : total / size + 1)
    }
    
    var hasPrevPage:Bool {
        totalPage > 1 && current > 1
    }
    var hasNextPage:Bool {
        totalPage > 1 && current < totalPage
    }
    
    var description: String {
        return "Page:[cursor:\(cursor), size:\(size), total:\(total)]"
    }
}
