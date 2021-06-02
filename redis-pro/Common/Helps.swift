//
//  Helps.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/19.
//

import Foundation

struct Helps {
    static let PAGE_KEYS = "redis dbsize 命令返回的数量."
    
    static let SCAN_COUNT = "redis scan 命令 COUNT 参数, 实际返回数量不保证一致."
    
    static let SEARCH_PATTERN = "支持redis glob 风格的模式参数, 示例: key*, re?is"
    static let TTL_HELP = "单位(秒), -1表示永不过期"
    
    static let DELETE_KEY_CONFIRM_TITLE = "Delete key '%@'?"
    static let DELETE_KEY_CONFIRM_MESSAGE = "Are you sure you want to delete the key '%@'? This operation cannot be undone."
    
    static let DELETE_HASH_FIELD_CONFIRM_TITLE = "Delete hash field '%@'?"
    static let DELETE_HASH_FIELD_CONFIRM_MESSAGE = "Are you sure you want to delete the hash field '%@'? This operation cannot be undone."
    
    
    static let DELETE_LIST_ITEM_CONFIRM_TITLE = "Delete list item '%@'?"
    static let DELETE_LIST_ITEM_CONFIRM_MESSAGE = "Are you sure you want to delete the list item '%@'? This operation cannot be undone."
    
    static let KEY_NOT_EXIST = "Not exist key: '%@'!"
    static let SET_ELE_NOT_EXIST = "Not exist key: '%@', element: '%@'!"
    
    static let REFRESH = "Refresh"
    
}
