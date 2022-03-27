//
//  RedisClientSet.swift
//  redis-pro
//
//  Created by chengpan on 2022/3/6.
//

import Foundation
import RediStack


// set
extension RediStackClient {
    
    func pageSet(_ key:String, page: Page) async -> [String?] {
        
        logger.info("redis set page, key: \(key), page: \(page)")
        
        begin()
        defer {
            complete()
        }
        
        do {
            
            let match = page.keywords.isEmpty ? nil : page.keywords
            
            let set:[String?] = [String?]()
            let cursor:Int = 0
            let maxCount = page.current * page.size
            
            let res = try await recursionSScan(key, keywords: match, cursor: cursor, maxCount: maxCount, items: set)
            let start = (page.current - 1) * page.size
            
            if res.1.count <= start {
                return []
            }
            
            let end = min(start + page.size - 1, res.1.count)
            let pageData:[String?] = Array(res.1[start..<end])
            
            let total = try await recursionSScanTotal(key, keywords: match)
            page.total = total
            
            return pageData
        } catch {
            handleError(error)
        }
        return []
    }
    
    // 递归取出包含分页的数据
    private func recursionSScan(_ key:String, keywords:String?, cursor:Int, maxCount:Int, items:[String?]) async throws -> (Int, [String?]) {
        if items.count >= maxCount {
            self.logger.info("recursion sscan get keys enough, max count: \(maxCount), current count: \(items.count)")
            return (cursor, items)
        } else {
            let res = try await sscan(key, keywords: keywords, cursor: cursor, count: recursionSize)
            
            let newItems:[String?] = items + res.1
            
            if res.0 == 0 {
                self.logger.info("recursion scan reach end, max count: \(maxCount), current count: \(newItems.count)")
                
                return (res.0, newItems)
            }
            
            self.logger.info("recursion scan get more keys, current count: \(newItems.count)")
            return try await recursionSScan(key, keywords: keywords, cursor: res.0, maxCount: maxCount, items: newItems)
        }
    }
    
    private func sscanTotal(_ key:String, keywords:String?, cursor:Int, total:Int) async throws -> Int {
        let res = try await sscan(key, keywords: keywords, cursor: cursor, count: 1000)
        let newTotal:Int = total + res.1.count
        
        if res.0 == 0 {
            self.logger.info("recursion scan total reach end, total: \(newTotal)")
            
            return newTotal
        }
        
        self.logger.info("recursion scan total get more, current total: \(newTotal)")
        return try await sscanTotal(key, keywords: keywords, cursor: res.0, total: newTotal)
        
    }
    
    private func recursionSScanTotal(_ key:String, keywords:String?) async throws -> Int {
        if isMatchAll(keywords) {
            logger.info("keywords is match all, use scard...")
            return try await scard(key)
        }
        
        let cursor:Int = 0
        let total:Int = 0
        
        return try await sscanTotal(key, keywords: keywords, cursor: cursor, total: total)
    }
    
    private func sscan(_ key:String, keywords:String?, cursor:Int, count:Int? = 1) async throws -> (Int, [String?]) {
        logger.debug("redis set scan, key: \(key) cursor: \(cursor), keywords: \(String(describing: keywords)), count:\(String(describing: count))")
        let conn = try await getConn()
        
        return try await withCheckedThrowingContinuation { continuation in
            
            conn.sscan(RedisKey(key), startingFrom: cursor, matching: keywords, count: count, valueType: String.self)
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
    
    func supdate(_ key:String, from:String, to:String) async -> Int {
        begin()
        defer {
            complete()
        }
        logger.info("redis set update, key: \(key), from: \(from), to: \(to)")
        
        do {
            let r = try await sremInner(key, ele: from)
            if r > 0 {
                return try await saddInner(key, ele: to)
            }
        } catch {
            handleError(error)
        }
        return 0
        
    }
    
    func srem(_ key:String, ele:String) async -> Int {
        begin()
        defer {
            complete()
        }
        
        do {
            return try await sremInner(key, ele: ele)
        } catch {
            handleError(error)
        }
        return 0
    }
    
    func sadd(_ key:String, ele:String) async -> Int {
        begin()
        defer {
            complete()
        }
        do {
            return try await saddInner(key, ele: ele)
        } catch {
            handleError(error)
        }
        return 0
    }
    
    private func scard(_ key:String) async throws -> Int {
        let conn = try await getConn()
        
        return try await withCheckedThrowingContinuation { continuation in
            
            conn.scard(of: RedisKey(key))
                .whenComplete({completion in
                    if case .success(let r) = completion {
                        continuation.resume(returning: r)
                    }
                    
                    else if case .failure(let error) = completion {
                        self.logger.error("redis scard error, key:\(key), error: \(error)")
                        continuation.resume(throwing: error)
                    }
                })
        }
    }
    
    private func sremInner(_ key:String, ele:String) async throws -> Int {
        let conn = try await getConn()
        
        return try await withCheckedThrowingContinuation { continuation in
            
            conn.srem(ele, from: RedisKey(key))
                .whenComplete({completion in
                    if case .success(let r) = completion {
                        continuation.resume(returning: r)
                    }
                    
                    else if case .failure(let error) = completion {
                        self.logger.error("redis set srem key:\(key), ele:\(ele), error: \(error)")
                        continuation.resume(throwing: error)
                    }
                })
        }
    }
    
    
    private func saddInner(_ key:String, ele:String) async throws -> Int {
        let conn = try await getConn()
        
        return try await withCheckedThrowingContinuation { continuation in
            
            conn.sadd(ele, to: RedisKey(key))
                .whenComplete({completion in
                    if case .success(let r) = completion {
                        continuation.resume(returning: r)
                    }
                    
                    else if case .failure(let error) = completion {
                        self.logger.error("redis set add key:\(key), ele:\(ele), error: \(error)")
                        continuation.resume(throwing: error)
                    }
                })
        }
    }
    
    
}

