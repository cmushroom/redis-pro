//
//  RedisClient.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/13.
//

import Foundation
import NIO
import RediStack
import Logging

class RediStackClient{
    var connection:RedisConnection
    
    let logger = Logger(label: "redi-client")
    
    init(connection:RedisConnection) {
        self.connection = connection
    }
    
    func queryKeysPage() -> Void {
    
    }
}
