//
//  RedisInfoItemModel.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/7/19.
//

import Foundation

class RedisInfoItemModel: NSObject {
    @objc var section:String = ""
    @objc var key:String = ""
    @objc var value:String = ""
    
    @objc var desc:String {
        let tip:String = NSLocalizedString("REDIS_INFO_\(section)_\(key)".uppercased(), tableName: nil, bundle: Bundle.main, value: "", comment: "")
        return tip
    }
    
    override init() {
    }
    
    init(section:String, key:String, value:String) {
        self.section = section
        self.key = key
        self.value = value
    }
    
}
