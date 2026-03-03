//
//  ErrorExt.swift
//  redis-pro
//
//  Created by chengpanwang on 2025/2/5.
//

import Foundation
import RediStack

extension RedisConnectionPoolError {
    var message: String {
        switch self {
            
        case .timedOutWaitingForConnection:
            return "Timeout on establishing connection!"
         
        case .poolClosed:
            return "The connection pool is closed."
        default:
            return "\(self)"
        
        }
    }
}
