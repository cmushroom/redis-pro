//
//  RedisFavoriteModel.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/3/29.
//

import Foundation
import SwiftUI
import Logging

class RedisFavoriteModel:ObservableObject {
    @Published var redisModels: [RedisModel] = [RedisModel](repeating: RedisModel(), count: 1)
    var lastRedisModelId:String?
    
    let userDefaults = UserDefaults.standard
    
    let logger = Logger(label: "redis-favorite-model")
    
    private func getAll() -> [Dictionary<String, Any>] {
        let redisDicts = userDefaults.array(forKey: UserDefaulsKeysEnum.RedisFavoriteListKey.rawValue)
        logger.info("get all redis models from user defaults: \(String(describing: redisDicts))")
        
        return (redisDicts ?? [Dictionary<String, Any>]()) as! [Dictionary<String, Any>]
    }
    
    func loadAll() -> Void {
        redisModels.removeAll()
        
        let redisDicts = getAll()
        
        redisDicts.forEach{ (element) in
            redisModels.append(RedisModel(dictionary: element))
        }
        
        if redisModels.count == 0 {
            redisModels.append(RedisModel())
        }
        
        self.lastRedisModelId = userDefaults.string(forKey: UserDefaulsKeysEnum.RedisLastUseIdKey.rawValue)
        logger.info("last select redis model id: \(String(describing: lastRedisModelId))")
    }
    
    func saveLast(redisModel:RedisModel) -> Void {
        userDefaults.setValue(redisModel.id, forKey: UserDefaulsKeysEnum.RedisLastUseIdKey.rawValue)
    }
    
    func save(redisModel:RedisModel) -> Void {
        var savedRedisList:[Dictionary<String, Any>] = getAll()
        
        if let index = savedRedisList.firstIndex(where: { (e) -> Bool in
            return e["id"] as! String == redisModel.id
        }) {
            savedRedisList[index] = redisModel.dictionary
        } else {
            savedRedisList.append(redisModel.dictionary)
        }
        
        userDefaults.set(savedRedisList, forKey: UserDefaulsKeysEnum.RedisFavoriteListKey.rawValue)
        loadAll()
        logger.info("save redis to favorite complete")
    }
    
    
    func delete(redisModel:RedisModel) -> String? {
        return delete(id: redisModel.id)
    }
    
    
    func delete(id:String) -> String? {
        var savedRedisList:[Dictionary] = getAll()
        
        var nextId:String?
        
        if let index = savedRedisList.firstIndex(where: { (e) -> Bool in
            return e["id"] as! String == id
        }) {
            if savedRedisList.count > index + 1 {
                nextId = savedRedisList[index + 1]["id"] as? String
            }
            
            savedRedisList.remove(at: index)
            userDefaults.set(savedRedisList, forKey: UserDefaulsKeysEnum.RedisFavoriteListKey.rawValue)
            logger.info("remove redis from favorite complete, id:\(id)")
          
        
            loadAll()
        }
        return nextId
    }
    
}
