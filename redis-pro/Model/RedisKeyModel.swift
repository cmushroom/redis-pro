//
//  RedisKeyModel.swift
//  redis-pro
//
//  Created by chengpan on 2021/4/4.
//

import Foundation

struct RedisKeyModel:Identifiable {
    var id: String
    var type: String
    var ttl: Int = -1
    
    init(id:String, type:String) {
        self.id = id
        self.type = type
    }
}
