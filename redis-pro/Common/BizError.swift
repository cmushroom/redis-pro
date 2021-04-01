//
//  BizError.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/1/28.
//

import Foundation

enum BizError: Error{
    case RedisError(message: String)
}
