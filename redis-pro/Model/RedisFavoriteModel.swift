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
    @Published var redisModels: [RedisModel] = [RedisModel](repeating: RedisModel(), count: 0)
    let userDefaults = UserDefaults.standard
    
    let logger = Logger(label: "redis-favorite-model")
    
    func loadAll() -> Void {
        redisModels.removeAll()
        
        let redisDicts = userDefaults.array(forKey: UserDefaulsKeysEnum.RedisFavoriteListKey.rawValue)
        logger.info("load redis models from user defaults: \(String(describing: redisDicts))")
        logger.info("orgin redisModels capacity \(redisModels.capacity )")
        redisDicts?.forEach{ (element) in
            redisModels.append(RedisModel(dictionary: element as! [String : Any]))
            print("hello \(redisModels.capacity )  \(element)")
        }
        logger.info("orgin redisModels capacity \(redisModels.capacity )")
        
        if redisModels.count == 0 {
            redisModels.append(RedisModel())
        }
        
    }
    
    func save(redisModel:RedisModel) -> Void {
        var savedRedisList:[Dictionary] = userDefaults.object(forKey: UserDefaulsKeysEnum.RedisFavoriteListKey.rawValue) as? [Dictionary<String, Any>] ?? [Dictionary]()
        logger.info("get user favorite redis: \(savedRedisList)")
        
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
    
    
    func delete(redisModel:RedisModel) -> Void {
        delete(id: redisModel.id)
    }
    
    func delete(id:String) -> Void {
        var savedRedisList:[Dictionary] = userDefaults.object(forKey: UserDefaulsKeysEnum.RedisFavoriteListKey.rawValue) as? [Dictionary<String, Any>] ?? [Dictionary]()
        logger.info("get user favorite redis: \(savedRedisList)")
        
        if let index = savedRedisList.firstIndex(where: { (e) -> Bool in
            return e["id"] as! String == id
        }) {
            savedRedisList.remove(at: index)
            userDefaults.set(savedRedisList, forKey: UserDefaulsKeysEnum.RedisFavoriteListKey.rawValue)
            logger.info("remove redis from favorite complete, id:\(id)")
            
            loadAll()
        }
    }
    
}
