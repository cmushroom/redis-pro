//
//  KeyDelModel.swift
//  redis-pro
//
//  Created by chengpan on 2023/7/30.
//

import Foundation

class KeyDelModel: RedisKeyModel {
    var status: Int = 0
    
    var statusText: String {
        status == 0 ? "Ready" : ( status == 1 ? "Deleted" : "Delete Fail!")
    }
    
    convenience init(_ keyModel: RedisKeyModel) {
        self.init(keyModel.key, type: keyModel.type)
        self.status = 0
    }
}
