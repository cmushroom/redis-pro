//
//  RedisClientConfig.swift
//  redis-pro
//
//  Created by chengpan on 2022/3/6.
//

import Foundation
import RediStack


// MARK: -config
extension RediStackClient {
    func getConfigList(_ pattern:String = "*") async -> [RedisConfigItemModel] {
        logger.info("get redis config list, pattern: \(pattern)...")
        
        let command: RedisCommand<[RedisConfigItemModel]> = .configList(pattern)
        return await send(command, [])
    }
    
    func configRewrite() async -> Bool {
        logger.info("redis config rewrite ...")
        let command: RedisCommand<Bool> = .configRewrite()
        return await send(command, false)
        
    }
    
    func getConfigOne(key:String) async -> String? {
        logger.info("get redis config ...")
        let command: RedisCommand<String> = .getConfig(key)
        return await send(command)
    }
    
    
    func setConfig(key:String, value:String) async -> Bool {
        logger.info("set redis config, key: \(key), value: \(value)")
        let command: RedisCommand<Bool> = .setConfig(key, value: value)
        return await send(command, false)
    }
    
}
