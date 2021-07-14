//
//  SlowLogModel.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/7/14.
//

import Foundation

class SlowLogModel:NSObject, Identifiable {
    @objc var id:String = UUID().uuidString
    @objc var timestamp:Int64 = 0
    @objc var cmd:String = UUID().uuidString
    
    override init() {
    }
    
}
