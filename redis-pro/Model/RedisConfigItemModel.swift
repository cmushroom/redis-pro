//
//  RedisConfigItemModel.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/7/21.
//

import Foundation

public class RedisConfigItemModel:NSObject, Identifiable {
    @objc var key:String = ""
    @objc var value:String = ""
    
    override init() {
    }
    
    init(key:String?, value:String?) {
        self.key = key ?? ""
        self.value = value ?? ""
    }
}
