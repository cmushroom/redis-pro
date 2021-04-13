//
//  Page.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/13.
//

import Foundation

struct Page {
    var current:Int = 1
    var size:Int = 50
    var total:Int = 0
    
    var totalPage:Int {
        total < 1 ? 0 : (total % size == 0 ? total / size : total / size + 1)
    }
}
