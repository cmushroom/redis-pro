//
//  RedisClientScan.swift
//  redis-pro
//
//  Created by chengpan on 2022/3/6.
//

import Foundation

extension RediStackClient {
    
    func isMatchAll(_ keywords:String?) -> Bool {
        guard let keywords = keywords else {
            return true
        }
        return keywords.isEmpty || keywords == "*" || keywords == "**"
    }
    
    func isScan(_ keywords:String) -> Bool {
        return keywords.isEmpty || keywords.contains("*") || keywords.contains("?")
    }
}
