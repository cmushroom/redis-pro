//
//  RedisClientZSet.swift
//  redis-pro
//
//  Created by chengpan on 2022/3/6.
//

import Foundation
import RediStack

// zset
extension RediStackClient {
    
    // zset operator
    
    func pageZSet(_ key:String, page: Page) async -> [RedisZSetItemModel] {
        logger.info("redis zset scan page, key: \(key), page: \(page)")
        
        begin()
        defer {
            complete()
        }
        do {
            let match = page.keywords.isEmpty ? nil : page.keywords
            
            let cursor:Int = 0
            let items:[(String, Double)?] = []
            let maxCount = page.current * page.size
            
            let res = try await recursionZScan(key, keywords: match, cursor: cursor, maxCount: maxCount, items: items)
            let start = (page.current - 1) * page.size
            
            if res.1.count <= start {
                return []
            }
            
            let end = min(start + page.size - 1, res.1.count)
            let pageData:[RedisZSetItemModel] = Array(res.1[start..<end]).map {
                RedisZSetItemModel(value: $0?.0 ?? "", score: "\($0?.1 ?? 0)")
            }
            
            let total = try await recursionZScanTotal(key, keywords: match)
            page.total = total
            
            return pageData
        } catch {
            self.handleError(error)
        }
        return []

    }
    
    // 递归取出包含分页的数据
    private func recursionZScan(_ key:String, keywords:String?, cursor:Int, maxCount:Int, items:[(String, Double)?]) async throws -> (Int, [(String, Double)?]) {
        if items.count >= maxCount {
            self.logger.info("recursion zscan get items enough, max count: \(maxCount), current count: \(items.count)")
            return (cursor, items)
        } else {
            let res = try await zscanAsync(key, keywords: keywords, cursor: cursor, count: recursionSize)
            let newItems:[(String, Double)?] = items + res.1
            
            if res.0 == 0 {
                self.logger.info("recursion zscan reach end, max count: \(maxCount), current count: \(newItems.count)")
                
                return (res.0, newItems)
            }
            
            self.logger.info("recursion zscan get more keys, current count: \(newItems.count)")
            return try await recursionZScan(key, keywords: keywords, cursor: res.0, maxCount: maxCount, items: newItems)
        }
    }
    
    private func zscanTotal(_ key:String, keywords:String?, cursor:Int, total:Int) async throws -> Int {
        let res = try await zscanAsync(key, keywords: keywords, cursor: cursor, count: 1000)
        let newTotal:Int = total + res.1.count
        
        if res.0 == 0 {
            self.logger.info("recursion zscan total reach end, total: \(newTotal)")
            return newTotal
        }
        
        self.logger.info("recursion zscan total get more, current total: \(newTotal)")
        return try await zscanTotal(key, keywords: keywords, cursor: res.0, total: newTotal)
    }
    
    private func recursionZScanTotal(_ key:String, keywords:String?) async throws -> Int {
        if isMatchAll(keywords) {
            logger.info("keywords is match all, use scard...")
            return try await zcard(key)
        }
        
        let cursor:Int = 0
        let total:Int = 0
        
        return try await zscanTotal(key, keywords: keywords, cursor: cursor, total: total)
    }
    
    
    private func zscanAsync(_ key:String, keywords:String?, cursor:Int, count:Int? = 1) async throws -> (Int, [(String, Double)?]) {
        
        logger.debug("redis set scan, key: \(key) cursor: \(cursor), keywords: \(String(describing: keywords)), count:\(String(describing: count))")
        
        let conn = try await getConn()
        
        return try await withCheckedThrowingContinuation { continuation in
            
            conn.zscan(RedisKey(key), startingFrom: cursor, matching: keywords, count: count, valueType: String.self)
                .whenComplete({completion in
                    if case .success(let r) = completion {
                        continuation.resume(returning: r)
                    }
                    else if case .failure(let error) = completion {
                        self.logger.error("redis set scan key:\(key) error: \(error)")
                        continuation.resume(throwing: error)
                    }
                })
            
        }
    }
    
    func zupdate(_ key:String, from:String, to:String, score:Double) async -> Bool {
        logger.info("update zset element key: \(key), from:\(from), to:\(to), score:\(score)")
        begin()
        defer {
            complete()
        }
 
        do {
            let r = try await zremInner(key, ele: from)
            if r > 0 {
                return try await zaddInner(key, score: score, ele: to)
            }
            
        } catch {
            handleError(error)
        }
        return false
    }
    
    func zadd(_ key:String, score:Double, ele:String) async -> Bool {
        begin()
        defer {
            complete()
        }
        do {
            return try await zaddInner(key, score: score, ele: ele)
        } catch {
            handleError(error)
        }
        
        return false
    }
    
    private func zaddInner(_ key:String, score:Double, ele:String) async throws -> Bool {
        let conn = try await getConn()
        
        return try await withCheckedThrowingContinuation { continuation in
            
            conn.zadd((element: ele, score: score), to: RedisKey(key))
                .whenComplete({completion in
                    if case .success(let r) = completion {
                        continuation.resume(returning: r)
                    }
                    else if case .failure(let error) = completion {
                        self.logger.error("redis zset zadd key:\(key) error: \(error)")
                        continuation.resume(throwing: error)
                    }
                })
            
        }
    }
    
    
    private func zcard(_ key:String) async throws -> Int {
        let conn = try await getConn()
        
        return try await withCheckedThrowingContinuation { continuation in
            
            conn.zcard(of: RedisKey(key))
                .whenComplete({completion in
                    if case .success(let r) = completion {
                        continuation.resume(returning: r)
                    }
                    
                    self.complete(completion, continuation: continuation)
                })
        }
    }
    
    func zrem(_ key:String, ele:String) async -> Int {
        begin()
        
        defer {
            complete()
        }
        do {
            return try await zremInner(key, ele: ele)
        } catch {
            handleError(error)
        }
        return 0
    }
    
    private func zremInner(_ key:String, ele:String) async throws -> Int {
        
        let conn = try await getConn()
        
        return try await withCheckedThrowingContinuation { continuation in
            
            conn.zrem(ele, from: RedisKey(key))
                .whenComplete({completion in
                    if case .success(let r) = completion {
                        continuation.resume(returning: r)
                    }
                    else if case .failure(let error) = completion {
                        continuation.resume(throwing: error)
                    }
                })
            
        }
        
    }
}
