//
//  RedisClientKeys.swift
//  redis-pro
//
//  Created by chengpan on 2022/3/6.
//

import Foundation
import RediStack
import Logging

// key
extension RediStackClient {
    
    private func keyScan(cursor:Int, keywords:String?, count:Int? = 1) async throws -> (cursor:Int, keys:[String]) {
        logger.debug("redis keys scan, cursor: \(cursor), keywords: \(String(describing: keywords)), count:\(String(describing: count))")
        
        
        let conn = try await getConn()
        
        return try await withCheckedThrowingContinuation { continuation in
            conn.scan(startingFrom: cursor, matching: keywords, count: count)
                .whenComplete({completion in
                    if case .success(let r) = completion {
                        continuation.resume(returning: r)
                    }
                    else if case .failure(let error) = completion {
                        self.logger.error("redis keys scan error \(error)")
                        continuation.resume(throwing: error)
                    }
                })
        }
    }
    
    // 递归取出包含分页的数据
    private func recursionScan(_ keywords:String?, cursor:Int, maxCount:Int, keys:[String]) async throws -> (cursor:Int, keys:[String]) {
        if keys.count >= maxCount {
            self.logger.info("recursion scan get keys enough, max count: \(maxCount), current count: \(keys.count)")
            return (cursor, keys)
        } else {
            let res = try await keyScan(cursor: cursor, keywords: keywords, count: recursionSize)
            let newKeys = keys + res.keys
            
            if res.cursor == 0 {
                self.logger.info("recursion scan reach end, max count: \(maxCount), current count: \(keys.count)")
                
                return (res.cursor, newKeys)
            }
            
            self.logger.info("recursion scan get more keys, current count: \(newKeys.count)")
            return try await self.recursionScan(keywords, cursor: res.cursor, maxCount: maxCount, keys: newKeys)
        }
    }
    
    private func scanTotal(_ keywords:String?, cursor:Int, total:Int) async throws -> Int {
        let res = try await keyScan(cursor: cursor, keywords: keywords, count: recursionCountSize)
        let newTotal:Int = total + res.keys.count
        if res.cursor == 0 {
            self.logger.info("recursion scan total reach end, total: \(newTotal)")
            
            return newTotal
        }
        
        self.logger.info("recursion scan total get more, current total: \(newTotal)")
        return try await self.scanTotal(keywords, cursor: res.cursor, total: newTotal)
    }
    
    private func recursionScanTotal(_ keywords:String?) async throws -> Int {
        if isMatchAll(keywords ?? "") {
            logger.info("keywords is match all, use dbsize...")
            return await dbsize()
        }
        
        let cursor:Int = 0
        let total:Int = 0
        
        return try await scanTotal(keywords, cursor: cursor, total: total)
    }
    
    func pageKeys(_ page:Page) async -> [RedisKeyModel] {
        begin()
        
        let stopwatch = Stopwatch.createStarted()
        
        logger.info("redis keys page scan, page: \(page)")
        
        let isScan = isScan(page.keywords)
        let match = page.keywords.isEmpty ? nil : page.keywords
        
        let keys:[String] = [String]()
        let cursor:Int = 0
        
        defer {
            self.logger.info("keys scan complete, spend: \(stopwatch.elapsedMillis()) ms")
            complete()
        }
        
        do {
            // 带有占位符的情况，使用
            if isScan {
                async let totalAsync = recursionScanTotal(match)
                
                async let res = self.recursionScan(match, cursor: cursor, maxCount: page.size, keys: keys)
                
                let total = try await totalAsync
                let keys = try await res.keys
                
                let start = (page.current - 1) * page.size
                
                if keys.count <= start {
                    return []
                }
                
                let end = min(start + page.size - 1, keys.count)
                let pageData:[String] = Array(keys[start..<end])
                
                
                DispatchQueue.main.async {
                    page.total = total
                }
                return await self.toRedisKeyModels(pageData)
            } else {
                let exist = await self.exist(page.keywords)
                if exist {
                    page.total = 1
                    return await self.toRedisKeyModels([page.keywords])
                } else {
                    page.total = 0
                    return []
                }
            }
            
        } catch {
            self.logger.error("get key type error: \(error)")
            self.handleError(error)
        }

        return []
    }
    
    func toRedisKeyModels(_ keys:[String]) async -> [RedisKeyModel] {
        if keys.isEmpty {
            return []
        }
        
        var redisKeyModels = [RedisKeyModel]()
        
        let typeDict = await getTypes(keys)
        
        for key in keys {
            redisKeyModels.append(RedisKeyModel(key, type: typeDict[key] ?? RedisKeyTypeEnum.NONE.rawValue))
        }
        
        return redisKeyModels
    }
    
}
