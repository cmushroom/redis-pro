//
//  RedisKeyModel.swift
//  redis-pro
//
//  Created by chengpan on 2021/4/4.
//

import Foundation
import Cocoa

class RedisKeyModel:NSObject, ObservableObject, Identifiable {
    @objc @Published var key: String = ""
    @objc @Published var type: String = RedisKeyTypeEnum.STRING.rawValue
    @Published var ttl: Int = -1
    @Published var isNew: Bool = false
    
    private var _id:String = ""
    var id:String {
        if isNew {
            return _id
        }
        return key
    }
    
    override init() {}
    
    convenience init(_ key:String, type:String) {
        self.init()
        self.key = key
        self.type = type
    }
    
    func copyValue(_ redisKeyModel:RedisKeyModel) {
        self.isNew =  redisKeyModel.isNew
        self.key = redisKeyModel.key
        self.type = redisKeyModel.type
    }
    
    func initNew() -> Void {
        self.isNew = true
        self.key = generateKey()
        self._id = self.key
        self.type = RedisKeyTypeEnum.STRING.rawValue
    }
    
    private func generateKey() -> String {
        return "NEW_KEY_\(Date().millis)"
    }
    
    override var description: String {
        return "RedisKeyModel:[key:\(key), type:\(type), isNew:\(isNew)]"
    }
    
    public static func == (lhs: RedisKeyModel, rhs: RedisKeyModel) -> Bool {
        // 需要比较的值
        return lhs.id == rhs.id
    }
}

extension RedisKeyModel {
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
