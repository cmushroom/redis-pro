//
//  AlertContext.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/14.
//

import Foundation

struct AlertContext {
    var visible:Bool = false
    var msg:String = ""
    
    init() {
    }
    
    init(_ visible:Bool, msg:String) {
        self.visible = visible
        self.msg = msg
    }
}
