//
//  RedisKeyModel.swift
//  redis-pro
//
//  Created by chengpan on 2021/4/4.
//

import Foundation
import Cocoa

class RedisKeyModel:NSObject, ObservableObject, Identifiable {
    @Published var key: String = ""
    @Published var type: String = RedisKeyTypeEnum.STRING.rawValue
    var ttl: Int = -1
    @Published var isNew: Bool = false
    
    var id:String {
        key
    }
    
    override init() {}
    
    convenience init(_ isNew:Bool) {
        self.init()
        self.isNew = isNew
    }
    convenience init(_ key:String, type:String) {
        self.init()
        self.key = key
        self.type = type
    }
    
    func initNew() -> Void {
        self.isNew = true
        self.key = "NEW_KEY_\(Date().millis)"
        self.type = RedisKeyTypeEnum.STRING.rawValue
    }
    
    func initKey(_ nsRedisKeyModel:NSRedisKeyModel) {
        self.isNew = false
        self.key = nsRedisKeyModel.key
        self.type = nsRedisKeyModel.type
    }
    
    convenience init(_ nsRedisKeyModel:NSRedisKeyModel) {
        self.init(nsRedisKeyModel.key, type: nsRedisKeyModel.type)
    }
    
    override var description: String {
        return "RedisKeyModel:[key:\(key), type:\(type), isNew:\(isNew)]"
    }
    
    public static func == (lhs: RedisKeyModel, rhs: RedisKeyModel) -> Bool {
        // 需要比较的值
        return lhs.id == rhs.id
    }
}

class NSRedisKeyModel:NSObject, ObservableObject, Identifiable {
    @objc @Published var key: String
    @objc @Published var type: String
    
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
