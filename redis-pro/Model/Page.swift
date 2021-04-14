//
//  Page.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/13.
//

import Foundation

class Page {
    var cursor:Int = 0
    var current:Int = 1
    var size:Int = 50
    var total:Int = 0
    
    var totalPage:Int {
        total < 1 ? 0 : (total % size == 0 ? total / size : total / size + 1)
    }
    
    var start:Int {
        (current - 1) *  size
    }
}
