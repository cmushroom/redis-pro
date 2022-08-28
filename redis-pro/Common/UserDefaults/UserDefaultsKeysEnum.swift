//
//  UserDefaultKeys.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/1/29.
//

import Foundation


enum UserDefaulsKeysEnum: String {
    case RedisFavoriteListKey = "RedisFavoriteListKey"
    case RedisLastUseIdKey = "RedisLastUseIdKey"
    // 列表默认选中类型, last:最后一个, id: 上次成功连接的redis id
    case RedisFavoriteDefaultSelectType = "User.defaultFavorite"
    // color scheme
    case AppColorScheme = "App.ColorScheme"
    // keepalive second
    case AppKeepalive = "App.Keepalive"
    
}
