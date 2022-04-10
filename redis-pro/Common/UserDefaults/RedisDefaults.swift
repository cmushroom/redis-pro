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
    
    static var defaultrRedisModels: [RedisModel] = [RedisModel()]
    
    static func getAll() -> [RedisModel] {
        let redisDicts:[Dictionary<String, Any>]? = getAllDict()
        
        guard let redisDicts = redisDicts else {
            return  defaultrRedisModels
        }
        
        if redisDicts.count == 0 {
            return  defaultrRedisModels
        }

        var redisModels:[RedisModel] = []
        redisDicts.forEach{ (element) in
            let item = RedisModel(dictionary: element)
            redisModels.append(item)
        }
        
        logger.info("load all redis models from user defaults: \(String(describing: redisDicts))")
        
        return redisModels
    }
    
    static func getLastId() -> String? {
        return userDefaults.string(forKey: UserDefaulsKeysEnum.RedisLastUseIdKey.rawValue)
    }
    
    private static func getAllDict() -> [Dictionary<String, Any>]? {
        return userDefaults.array(forKey: UserDefaulsKeysEnum.RedisFavoriteListKey.rawValue) as? [Dictionary<String, Any>]
    }
    
//    func loadAll() -> Void {
//        redisModels.removeAll()
//
//        let redisDicts = getAll()
//
//        redisDicts.forEach{ (element) in
//            let item = RedisModel(dictionary: element)
//            redisModels.append(item)
//        }
//
//        if redisModels.count == 0 {
//            let item = RedisModel()
//            redisModels.append(item)
//        }
//
//        self.lastRedisModelId = userDefaults.string(forKey: UserDefaulsKeysEnum.RedisLastUseIdKey.rawValue)
//        logger.info("last select redis model id: \(String(describing: lastRedisModelId))")
//    }
    
    static func saveLast(_ redisModel:RedisModel) -> Void {
        userDefaults.setValue(redisModel.id, forKey: UserDefaulsKeysEnum.RedisLastUseIdKey.rawValue)
    }
    
    static func save(_ redisModel:RedisModel) -> Void {
        var savedRedisList:[Dictionary<String, Any>] = getAllDict() ?? [Dictionary<String, Any>]()
        
        if let index = savedRedisList.firstIndex(where: { (e) -> Bool in
            return e["id"] as! String == redisModel.id
        }) {
            savedRedisList[index] = redisModel.dictionary
        } else {
            savedRedisList.append(redisModel.dictionary)
        }
        
        userDefaults.set(savedRedisList, forKey: UserDefaulsKeysEnum.RedisFavoriteListKey.rawValue)
        logger.info("save redis to user defaults complete")
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
