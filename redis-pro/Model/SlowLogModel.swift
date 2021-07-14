//
//  SlowLogModel.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/7/14.
//

import Foundation

class SlowLogModel:NSObject, Identifiable {
    @objc var id:String = ""
    @objc var timestamp:Int64 = 0
    @objc var cmd:String = ""
    
    override init() {
    }
    
}
