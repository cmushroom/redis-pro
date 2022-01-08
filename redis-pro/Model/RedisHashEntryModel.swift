//
//  RedisHashEntryModel.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/7/16.
//

import Foundation

class RedisHashEntryModel:NSObject, Identifiable, ObservableObject {
    @objc @Published var field:String = ""
    @objc @Published var value:String = ""
    @Published var isNew = false
    
    var id:String {
        self.field
    }
    
    override init() {
    }
    
    init(field:String, value:String?) {
        self.field = field
        self.value = value ?? ""
    }
}
