//
//  RediStackClientKey.swift
//  redis-pro
//
//  Created by chengpan on 2022/8/21.
//

import Foundation
import RediStack

// MARK: - string operator
extension RediStackClient {

    /**
     set value expire(seconds)
     */
    func set(_ key:String, value:String, ex:Int = -1) async -> Void {
        logger.info("set value, key:\(key), value:\(value), ex:\(ex)")
        
        let command:RedisCommand<Void> = ex == -1 ? .set(RedisKey(key), to: value) : .setex(RedisKey(key), to: value, expirationInSeconds: ex)
        
        await send(command)
    }
    
    func set(_ key:String, value:String) async -> Void {
        logger.info("set value, key:\(key), value:\(value)")
        
        await set(key, value:value, ex: -1)
    }
    
    func get(_ key:String) async -> String {
        logger.info("get value, key:\(key)")
        
        let command:RedisCommand<RESPValue?> = .get(RedisKey(key))
        let r = await send(command)
        return r??.description ?? Const.EMPTY_STRING
    }
    
    func getRange(_ key:String, start:Int = 0, end:Int) async -> String {
        logger.info("get value range, key:\(key), start:\(start), end:\(end)")
        
        let command:RedisCommand<String> = .getRange(key, start: start, end: end)
        let r = await send(command)
        return r?.description ?? Const.EMPTY_STRING
    }
    
    func strLen(_ key:String) async -> Int {
        logger.info("get value length, key:\(key)")
        
        let command:RedisCommand<Int> = .strln(RedisKey(key))
        return await send(command, 0)
    }
    
    func del(_ key:String) async -> Int {
        self.logger.info("delete key \(key)")
        
        let command:RedisCommand<Int> = .del([RedisKey(key)])
        return await send(command, 0)
    }
    
    func del(_ keys:[String]) async -> Int {
        self.logger.info("delete key \(keys)")
        guard keys.count > 0 else {
            return 0
        }
        
        let command:RedisCommand<Int> = .del(keys.map({RedisKey($0)}))
        return await send(command, 0)
    }
    
    func expire(_ key:String, seconds:Int = -1) async -> Bool {
        logger.info("set key expire key:\(key), seconds:\(seconds)")
        
        do {
            
            let maxSeconds:Int64 = INT64_MAX / (1000 * 1000 * 1000)
            try Assert.isTrue(seconds < maxSeconds, message: "过期时间最大值不能超过 \(maxSeconds) 秒")
            
            let command:RedisCommand<Bool> = seconds < 0 ?
                // PERSIST
                .init(keyword: "PERSIST", arguments: [.init(from: key)], mapValueToResult: {
                    return $0.int == 1
                }) : .expire(RedisKey(key), after: .seconds(Int64(seconds)))
            return await send(command, false)
            
        } catch {
            handleError(error)
        }
        return false
    }
    
    func exist(_ key:String) async -> Bool {
        logger.info("get key exist: \(key)")
        let command:RedisCommand<Int> = .exists(RedisKey(key))
        return await send(command) == 1
    }
    
    func ttl(_ key:String) async -> Int {
        logger.info("get ttl key: \(key)")
        let command:RedisCommand<RedisKey.Lifetime> = .ttl(RedisKey(key))
        return ttlSecond(await _send(command, RedisKey.Lifetime.keyDoesNotExist))
    }
    
    func objectEncoding(_ key:String) async -> String {
        logger.info("get object encoding, key: \(key)")
        let command:RedisCommand<String> = .objectEncoding(key)
        return await _send(command, "")
    }
    
    func getTypes(_ keys:[String]) async -> [String:String] {
        return await withTaskGroup(of: (String, String).self) { group in
            var typeDict = [String:String]()
            
            // adding tasks to the group and fetching movies
            for key in keys {
                group.addTask {
                    let type = await self.type(key)
                    return (key, type)
                }
            }
            
            for await type in group {
                typeDict[type.0] = type.1
            }
            
            return typeDict
        }
    }
    
    private func type(_ key:String) async -> String {
        let command:RedisCommand<String> = .type(key)
        return await _send(command, RedisKeyTypeEnum.NONE.rawValue)
    }
    
    
    func rename(_ oldKey:String, newKey:String) async -> Bool {
        logger.info("rename key, old key:\(oldKey), new key: \(newKey)")
        
        let command:RedisCommand<Int> = .renamenx(oldKey, newKey: newKey)
        let r = await send(command, 0)
        if r == 0 {
            Messages.show("rename key error, new key: \(newKey) already exists.")
        }
        
        return r > 0
    }
}
