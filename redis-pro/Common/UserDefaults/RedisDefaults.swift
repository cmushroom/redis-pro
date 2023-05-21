//
//  RedisDefaults.swift
//  redis-pro
//
//  Created by chengpan on 2022/4/10.
//

import Foundation
import Logging

class RedisDefaults {
    static let userDefaults = UserDefaults.standard
    static let logger = Logger(label: "redis-defaults")
    
    static var defaultRedisModels: [RedisModel] = [RedisModel()]
    
    // 获取用户保存的redis, 如果没有自动初始化一个
    static func getAll() -> [RedisModel] {
        let redisDicts:[Dictionary<String, Any>]? = getAllDict()
        
        guard let redisDicts = redisDicts else {
            return  defaultRedisModels
        }
        
        if redisDicts.count == 0 {
            return  defaultRedisModels
        }

        var redisModels:[RedisModel] = []
        redisDicts.forEach{ (element) in
            let item = RedisModel(dictionary: element)
            redisModels.append(item)
        }
        
        logger.info("load all redis models from user defaults: \(String(describing: redisDicts))")
        
        return redisModels
    }
    
    // 默认选中类型 last:最后一个, id: 上次成功连接的redis id
    static func defaultSelectType() -> String {
        return userDefaults.string(forKey: UserDefaulsKeysEnum.RedisFavoriteDefaultSelectType.rawValue) ?? "last"
    }
    
    // 最后使用的id
    static func getLastId() -> String? {
        return userDefaults.string(forKey: UserDefaulsKeysEnum.RedisLastUseIdKey.rawValue)
    }
    
    // string 最大显示长度
    static func getStringMaxLength() -> Int {
        let string:String? = userDefaults.string(forKey: UserDefaulsKeysEnum.AppStringMaxLength.rawValue)
        if let string = string {
            return Int(string) ?? Const.DEFAULT_STRING_MAX_LENGTH
        }
        
        return Const.DEFAULT_STRING_MAX_LENGTH
    }
    
    
    private static func getAllDict() -> [Dictionary<String, Any>]? {
        return userDefaults.array(forKey: UserDefaulsKeysEnum.RedisFavoriteListKey.rawValue) as? [Dictionary<String, Any>]
    }
    
    static func saveLastUse(_ redisModel:RedisModel) -> Void {
        userDefaults.setValue(redisModel.id, forKey: UserDefaulsKeysEnum.RedisLastUseIdKey.rawValue)
    }
    
    static func save(_ redisModel:RedisModel) -> Int {
        var savedRedisList:[Dictionary<String, Any>] = getAllDict() ?? [Dictionary<String, Any>]()
        
        var r:Int = 0
        if let index = savedRedisList.firstIndex(where: { (e) -> Bool in
            return e["id"] as! String == redisModel.id
        }) {
            savedRedisList[index] = redisModel.dictionary
            r = index
        } else {
            savedRedisList.append(redisModel.dictionary)
            r = savedRedisList.count - 1
        }
        
        userDefaults.set(savedRedisList, forKey: UserDefaulsKeysEnum.RedisFavoriteListKey.rawValue)
        logger.info("save redis to user defaults complete")
        return r
    }
    
    static func save(_ redisModels:[RedisModel]) -> Bool {
        let redisDics = redisModels.map { $0.dictionary }
        
        userDefaults.set(redisDics, forKey: UserDefaulsKeysEnum.RedisFavoriteListKey.rawValue)
        logger.info("save all redis to user defaults complete")
        return true
    }
    
    static func delete(redisModel:RedisModel) -> String? {
        return delete(id: redisModel.id)
    }
    
    
    static func delete(_ index:Int) -> Bool {
        var savedRedisList:[Dictionary] = getAllDict() ?? [Dictionary<String, Any>]()
        if savedRedisList.count < index + 1 {
            return  false
        }
        
        let  deletedRedis = savedRedisList[index]
        
        savedRedisList.remove(at: index)
        userDefaults.set(savedRedisList, forKey: UserDefaulsKeysEnum.RedisFavoriteListKey.rawValue)
        logger.info("remove redis from user defaults complete, redis: \(deletedRedis)")
        
        return true
    }
    
    static func delete(id:String) -> String? {
        var savedRedisList:[Dictionary] = getAllDict() ?? [Dictionary<String, Any>]()
        
        var nextId:String?
        
        if let index = savedRedisList.firstIndex(where: { (e) -> Bool in
            return e["id"] as! String == id
        }) {
            if savedRedisList.count > index + 1 {
                nextId = savedRedisList[index + 1]["id"] as? String
            }
            
            savedRedisList.remove(at: index)
            userDefaults.set(savedRedisList, forKey: UserDefaulsKeysEnum.RedisFavoriteListKey.rawValue)
            logger.info("remove redis from user defaults complete, id:\(id)")
        }
        return nextId
    }
}
