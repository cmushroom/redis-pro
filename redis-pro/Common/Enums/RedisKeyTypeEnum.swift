//
//  RedisKeyTypeEnum.swift
//  redis-pro
//
//  Created by chengpan on 2021/4/4.
//

import Foundation

enum RedisKeyTypeEnum: String,CaseIterable {
    case NONE = "none"
    case STRING = "string"
    case HASH = "hash"
    case LIST = "list"
    case SET = "set"
    case ZSET = "zset"
}
