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
    
    func pageSet(_ key:String, page: Page) async -> [String] {
        
        logger.info("redis set page, key: \(key), page: \(page)")
        
        begin()
        defer {
            complete()
        }
        
        do {
            try await assertExist(key)
            
            let isScan = isScan(page.keywords)
            var r:[String] = []
            
            if isScan {
                let match = page.keywords.isEmpty ? nil : page.keywords
                
                let pageData:[String] = try await setPageScan(key, page: page)
                r = r + pageData
                
                let total = try await setCountScan(key, keywords: match)
                page.total = total
            } else {
                let exist = try await sexist(key, ele: page.keywords)
                if exist {
                    r = [page.keywords]
                    page.total = 1
                }
            }
            return r
        } catch {
            handleError(error)
        }
        return []
    }
    
    
    
    private func setCountScan(_ key:String, keywords:String?) async throws -> Int {
        if isMatchAll(keywords ?? "") {
            logger.info("keywords is match all, use scard...")
            return try await scard(key)
        }
        
        var cursor:Int = 0
        var count:Int = 0
        
        while true {
            let res = try await sscan(key, keywords: keywords, cursor: cursor, count: dataCountScanCount)
            logger.info("set loop scan count, current cursor: \(cursor), total count: \(count)")
            cursor = res.0
            count = count + res.1.count
            
            // 取到结果，或者已满足分页数据
            if cursor == 0{
                break
            }
        }
        return count
    }
    
    private func setPageScan(_ key:String, page: Page) async throws -> [String] {
        let keywords = page.keywords.isEmpty ? nil : page.keywords
        var end:Int = page.end
        var cursor:Int = 0
        var keys:[String] = []
        
        while true {
            let res = try await sscan(key, keywords: keywords, cursor: cursor, count: dataScanCount)
            logger.info("set loop scan page, current cursor: \(cursor), total count: \(keys.count)")
            cursor = res.0
            keys = keys + res.1.map { $0 ?? ""}
            
            // 取到结果，或者已满足分页数据
            if cursor == 0 || keys.count >= end {
                break
            }
        }
        
        let start = page.start
        if start >= keys.count {
            return []
        }
        
        end = min(end, keys.count)
        return Array(keys[start..<end])
        
    }
    
    private func sscan(_ key:String, keywords:String?, cursor:Int, count:Int = 1) async throws -> (Int, [String?]) {
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
    
    private func sexist(_ key:String, ele:String?) async throws -> Bool{
        let conn = try await getConn()
        
        return try await withCheckedThrowingContinuation { continuation in
            
            conn.sismember(ele, of: RedisKey(key))
                .whenComplete({completion in
                    if case .success(let r) = completion {
                        continuation.resume(returning: r)
                    }
                    
                    else if case .failure(let error) = completion {
                        self.logger.error("redis set ele exist, key:\(key) error: \(error)")
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
            try Assert.isTrue(r > 0, message: "set element: `\(from)` is not exist!")
            
            return try await saddInner(key, ele: to)
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

