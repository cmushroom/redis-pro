//
//  SlowLogModel.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/7/14.
//

import Foundation

class SlowLogModel:NSObject, Identifiable {
    @objc var id:String = ""
    @objc var timestamp:Int = -1
    @objc var execTime:String = ""
    @objc var cmd:String = ""
    @objc var client:String = ""
    @objc var clientName:String = ""
    
    @objc var timestampFormat:String {
        timestamp == -1 ? MTheme.NULL_STRING : DateHelper.formatDateTime(timestamp: self.timestamp)
    }
    
    override init() {
    }
    
    init(id:String?, timestamp:Int?, execTime:String?, cmd:String?, client:String?, clientName:String?) {
        self.id = id ?? MTheme.NULL_STRING
        self.timestamp = timestamp ?? -1
        self.execTime = execTime ?? MTheme.NULL_STRING
        self.cmd = cmd ?? MTheme.NULL_STRING
        self.client = client ?? MTheme.NULL_STRING
        self.clientName = clientName ?? MTheme.NULL_STRING
    }
    
    
    static func == (lhs: SlowLogModel, rhs: SlowLogModel) -> Bool {
        return lhs.id == rhs.id
    }
}
