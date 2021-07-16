//
//  RedisSetItemModel.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/7/16.
//

import Foundation

class RedisZSetItemModel:NSObject, ObservableObject, Identifiable {
    @objc @Published var value:String = ""
    @objc @Published var score:String = ""
    
    var id:String {
        self.value
    }
    
    override init() {
    }
    
    init(value:String, score:String) {
        self.score = score
        self.value = value
    }
    
    
    override var description: String {
        return "ZSetItem:[value:\(value), score:\(score)]"
    }
}
