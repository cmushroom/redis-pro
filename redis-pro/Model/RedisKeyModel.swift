//
//  RedisKeyModel.swift
//  redis-pro
//
//  Created by chengpan on 2021/4/4.
//

import Foundation
import Cocoa

struct RedisKeyModel:Identifiable {
    var no:Int = 0
    var key: String
    var type: String
    var ttl: Int = -1
    var isNew: Bool = false
    
    var id:String {
        key
    }
    
    var description: String {
        return "RedisKeyModel:[key:\(key), type:\(type), ttl:\(ttl)]"
    }
}

class NSRedisKeyModel:NSObject, ObservableObject, Identifiable {
    @objc var no:Int = 0
    @objc @Published var key: String
    @objc @Published var type: String
    @Published var ttl: Int = -1
    @Published var isNew: Bool = false
    
    var id:String {
        key
    }
    
    // type 颜色
    @objc var typeColor: NSColor {
        switch type {
        case RedisKeyTypeEnum.STRING.rawValue:
            return NSColor.systemBlue
        case RedisKeyTypeEnum.HASH.rawValue:
            return NSColor.systemPink
        case RedisKeyTypeEnum.LIST.rawValue:
            return NSColor.systemOrange
        case RedisKeyTypeEnum.SET.rawValue:
            return NSColor.systemGreen
        case RedisKeyTypeEnum.ZSET.rawValue:
            return NSColor.systemTeal
        default:
            return NSColor.systemBrown
        }
    }
    
    convenience init(key:String, type:String) {
        self.init(key: key, type: type, isNew: false)
    }
    
    init(key:String, type:String, isNew:Bool) {
        self.key = key
        self.type = type
        self.isNew = isNew
    }
    
    init(redisKeyModel:RedisKeyModel) {
        self.key = redisKeyModel.key
        self.type = redisKeyModel.type
        self.isNew = redisKeyModel.isNew
    }
    
    public static func == (lhs: NSRedisKeyModel, rhs: NSRedisKeyModel) -> Bool {
           // 需要比较的值
           return lhs.id == rhs.id
       }
    
    override var description: String {
        return "RedisKeyModel:[key:\(key), type:\(type), ttl:\(ttl)]"
    }
}
