//
//  RedisSetItemModel.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/7/16.
//

import Foundation

class RedisZSetItemModel:NSObject, Identifiable {
    @objc var value:String = ""
    @objc var score:String = "0"
    
    var id:String {
        self.value
    }
    
    override init() {
    }
    
    init(value:String, score:String) {
        self.score = score
        self.value = value
    }
}
