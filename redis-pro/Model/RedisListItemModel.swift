//
//  RedisListItemModel.swift
//  redis-pro
//
//  Created by chengpan on 2022/5/22.
//

import Foundation

class RedisListItemModel: NSObject {
    
    @objc var index:Int = 0
    @objc var value:String = ""
    
    override init() {
    }
    
    init(_ index:Int, _ value:String) {
        self.index = index
        self.value = value
    }

    static func == (lhs: RedisListItemModel, rhs: RedisListItemModel) -> Bool {
        return lhs.index == rhs.index && lhs.value == rhs.value
    }
}
