//
//  BizError.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/1/28.
//

import Foundation

struct BizError: Error{
    public let message: String

    public var errorDescription: String? { return message }
    
    init(message:String) {
        self.message = message
    }
}
