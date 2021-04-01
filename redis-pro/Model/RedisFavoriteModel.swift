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
    
    func loadAll() -> Void {
        let redisDicts = userDefaults.array(forKey: UserDefaulsKeys.RedisFavoriteListKey.rawValue)
        logger.info("load redis models from user defaults: \(String(describing: redisDicts))")
        logger.info("orgin redisModels capacity \(redisModels.capacity )")
        redisDicts?.forEach{ (element) in
            redisModels.append(RedisModel(dictionary: element as! [String : Any]))
            print("hello \(redisModels.capacity )  \(element)")
        }
        logger.info("orgin redisModels capacity \(redisModels.capacity )")
    }
}
