//
//  RedisClientSet.swift
//  redis-pro
//
//  Created by chengpan on 2022/3/6.
//

import Foundation
import RediStack


// MARK: - set function
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
                
                let pageData:[String] = try await _setPageScan(key, page: page)
                r = r + pageData
                
                let total = try await _setCountScan(key, keywords: match)
                page.total = total
            } else {
                let exist = try await _sexist(key, ele: page.keywords)
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
    
    
    
    private func _setCountScan(_ key:String, keywords:String?) async throws -> Int {
        if isMatchAll(keywords ?? "") {
            logger.info("keywords is match all, use scard...")
            return try await _scard(key)
        }
        
        var cursor:Int = 0
        var count:Int = 0
        
        while true {
            let res = try await _sscan(key, keywords: keywords, cursor: cursor, count: dataCountScanCount)
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
    
    private func _setPageScan(_ key:String, page: Page) async throws -> [String] {
        let keywords = page.keywords.isEmpty ? nil : page.keywords
        var end:Int = page.end
        var cursor:Int = 0
        var keys:[String] = []
        
        while true {
            let res = try await _sscan(key, keywords: keywords, cursor: cursor, count: dataScanCount)
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
    
    private func _sscan(_ key:String, keywords:String?, cursor:Int, count:Int = 1) async throws -> (Int, [String?]) {
        logger.debug("redis set scan, key: \(key) cursor: \(cursor), keywords: \(String(describing: keywords)), count:\(String(describing: count))")
    
        let command: RedisCommand<(Int, [RESPValue])> = .sscan(RedisKey(key), startingFrom: cursor, matching: keywords, count: count)
        let r = try await _send(command)
        return (r.0, r.1.map { $0.string })
    }
    
    private func _sexist(_ key:String, ele:String?) async throws -> Bool{
        let command: RedisCommand<Bool> = .sismember(ele, of: RedisKey(key))
        return try await _send(command)
    }
    
    func supdate(_ key:String, from:String, to:String) async -> Int {
        begin()
        defer {
            complete()
        }
        logger.info("redis set update, key: \(key), from: \(from), to: \(to)")
        
        do {
            let r = try await _srem(key, ele: from)
            try Assert.isTrue(r > 0, message: "set element: `\(from)` is not exist!")
            
            return try await _sadd(key, ele: to)
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
            return try await _srem(key, ele: ele)
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
            return try await _sadd(key, ele: ele)
        } catch {
            handleError(error)
        }
        return 0
    }
    
    private func _scard(_ key:String) async throws -> Int {
        let command: RedisCommand<Int> = .scard(of: RedisKey(key))
        return try await _send(command)
    }
    
    private func _srem(_ key:String, ele:String) async throws -> Int {
        let command: RedisCommand<Int> = .srem(ele, from: RedisKey(key))
        return try await _send(command)
    }
    
    
    private func _sadd(_ key:String, ele:String) async throws -> Int {
        let command: RedisCommand<Int> = .sadd(ele, to: RedisKey(key))
        return try await _send(command)
    }
    
    
}

