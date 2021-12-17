//
//  RedisKeyModel.swift
//  redis-pro
//
//  Created by chengpan on 2021/4/4.
//

import Foundation
import Cocoa

struct RedisKeyModel:Identifiable, Equatable {
    var no:Int = 0
    var key: String = ""
    var type: String = RedisKeyTypeEnum.STRING.rawValue
    var ttl: Int = -1
    var isNew: Bool = false
    
    var id:String {
        key
    }
    
    init() {}
    
    init(_ isNew:Bool) {
        self.init()
        self.isNew = isNew
    }
    init(_ key:String, type:String) {
        self.init()
        self.key = key
        self.type = type
    }
    init(_ nsRedisKeyModel:NSRedisKeyModel) {
        self.init(nsRedisKeyModel.key, type: nsRedisKeyModel.type)
    }
    
    var description: String {
        return "RedisKeyModel:[key:\(key), type:\(type), ttl:\(ttl)]"
    }
    
    public static func == (lhs: RedisKeyModel, rhs: RedisKeyModel) -> Bool {
        // 需要比较的值
        return lhs.id == rhs.id
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
    
    override init() {
        self.key = ""
        self.type = RedisKeyTypeEnum.STRING.rawValue
        super.init()
    }
    convenience init(_ key:String, type:String) {
        self.init()
        self.key = key
        self.type = type
    }
    

    override var description: String {
        return "RedisKeyModel:[key:\(key), type:\(type)]"
    }
}
