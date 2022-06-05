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
        
        logger.info("redis zset page, key: \(key), page: \(page)")
        
        begin()
        defer {
            complete()
        }
        
        do {
            try await assertExist(key)
            
            let isScan = isScan(page.keywords)
            var r:[(String, String)] = []
            
            // 查询所有时使用 ZRANGEBYSCORE 按顺序返回
            if isMatchAll(page.keywords) {
                r = try await _zrangeByScore(key, page: page)
                page.total = try await _zcard(key)
            }
            else if isScan {
                let match = page.keywords.isEmpty ? nil : page.keywords
                
                let pageData = try await zsetPageScan(key, page: page)
                r = r + pageData
                
                let total = try await zsetCountScan(key, keywords: match)
                page.total = total
            } else {
                let score = try await _zscore(key, ele: page.keywords)
                if score != nil {
                    r = [(page.keywords, "\(score!)")]
                    page.total = 1
                }
            }
            return r.map { RedisZSetItemModel(value: $0.0, score: $0.1) }
        } catch {
            handleError(error)
        }
        return []
    }
    
    
    
    private func zsetCountScan(_ key:String, keywords:String?) async throws -> Int {
        if isMatchAll(keywords ?? "") {
            logger.info("keywords is match all, use scard...")
            return try await _zcard(key)
        }
        
        var cursor:Int = 0
        var count:Int = 0
        
        while true {
            let res = try await zscan(key, keywords: keywords, cursor: cursor, count: dataCountScanCount)
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
    
    private func zsetPageScan(_ key:String, page: Page) async throws -> [(String, String)] {
        let keywords = page.keywords.isEmpty ? nil : page.keywords
        var end:Int = page.end
        var cursor:Int = 0
        var keys:[(String, Double)?] = []
        
        while true {
            let res = try await zscan(key, keywords: keywords, cursor: cursor, count: dataScanCount)
            logger.info("set loop scan page, current cursor: \(cursor), total count: \(keys.count)")
            cursor = res.0
            keys = keys + res.1
            
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
        return Array(keys[start..<end]).compactMap {$0} .map { ($0!.0, "\($0!.1)") }
        
    }
    
    private func zscanTotal(_ key:String, keywords:String?, cursor:Int, total:Int) async throws -> Int {
        let res = try await zscan(key, keywords: keywords, cursor: cursor, count: 1000)
        let newTotal:Int = total + res.1.count
        
        if res.0 == 0 {
            self.logger.info("recursion zscan total reach end, total: \(newTotal)")
            return newTotal
        }
        
        self.logger.info("recursion zscan total get more, current total: \(newTotal)")
        return try await zscanTotal(key, keywords: keywords, cursor: res.0, total: newTotal)
    }
    
    
    private func zscan(_ key:String, keywords:String?, cursor:Int, count:Int? = 1) async throws -> (Int, [(String, Double)?]) {
        
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
            let r = try await _zrem(key, ele: from)
            try Assert.isTrue(r > 0, message: "set zset element: `\(from)` is not exist!")
            
            return try await _zadd(key, score: score, ele: to)
            
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
            return try await _zadd(key, score: score, ele: ele)
        } catch {
            handleError(error)
        }
        
        return false
    }
    
    private func _zadd(_ key:String, score:Double, ele:String) async throws -> Bool {
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
    
    
    private func _zcard(_ key:String) async throws -> Int {
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
            return try await _zrem(key, ele: ele)
        } catch {
            handleError(error)
        }
        return 0
    }
    
    private func _zrem(_ key:String, ele:String) async throws -> Int {
        
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
    
    private func _zscore(_ key:String, ele:String) async throws -> Double? {
        
        let conn = try await getConn()
        
        return try await withCheckedThrowingContinuation { continuation in
            
            conn.zscore(of: ele, in: RedisKey(key))
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
    
    private func _zrangeByScore(_ key:String, page:Page) async throws -> [(String, String)] {
        
        let conn = try await getConn()
        
        return try await withCheckedThrowingContinuation { continuation in
            
            conn.zrangebyscore(from: RedisKey(key), withMinimumScoreOf: .inclusive(Double.min), limitBy: (offset: page.start, count: page.size), includeScoresInResponse: true)
                .whenComplete({completion in
                    if case .success(let r) = completion {
                        continuation.resume(returning: self._mapRes(r))
                    }
                    else if case .failure(let error) = completion {
                        continuation.resume(throwing: error)
                    }
                })
            
        }
        
    }
    
    private func _mapRes(_ values: [RESPValue]?) -> [(String, String)]{
        guard let values = values else { return [] }
        guard values.count > 0 else { return [] }

        var result: [(String, String)] = []

        var index = 0
        repeat {
            result.append((values[index].string ?? "", values[index + 1].string ?? "0"))
            index += 2
        } while (index < values.count)
        
        return result
    }
}
