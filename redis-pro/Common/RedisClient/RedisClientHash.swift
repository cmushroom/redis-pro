//
//  RedisClientHash.swift
//  redis-pro
//
//  Created by chengpan on 2022/3/6.
//

import Foundation
import RediStack


// MARK: - hash function
// hash
extension RediStackClient {
    
    // hash operator
    
    func pageHash(_ key:String, page:Page) async -> [RedisHashEntryModel] {
        logger.info("redis hash field page scan, key: \(key), page: \(page)")
        
        begin()
        defer {
            complete()
        }
        do {
            try await assertExist(key)
            
            let isScan = isScan(page.keywords)
            var r:[RedisHashEntryModel] = []
            
            if isScan {
                let match = page.keywords.isEmpty ? nil : page.keywords
                
                let pageData:[(String, String?)] = try await _hashPageScan(key, page: page)
                r = pageData.map({
                    RedisHashEntryModel(field: $0.0, value: $0.1)
                })
                
                let total = try await _hashCountScan(key, keywords: match)
                page.total = total
            } else {
                let value = try await _hget(key, field: page.keywords)
                if value != nil {
                    r.append(RedisHashEntryModel(field: page.keywords, value: value))
                    page.total = 1
                }
            }
            return r
        } catch {
            handleError(error)
        }
        return []
    }
    
    func hset(_ key:String, field:String, value:String) async -> Bool {
        logger.info("redis hash hset key:\(key), field:\(field), value:\(value)")
        let command:RedisCommand<Bool> = .hset(RedisHashFieldKey(field), to: value, in: RedisKey(key))
        return await send(command, false)
    }
    
    func hdel(_ key:String, field:String) async -> Int {
        logger.info("redis hash hdel key:\(key), field:\(field)")
        let command:RedisCommand<Int> = .hdel([RedisHashFieldKey(field)], from: RedisKey(key))
        return await send(command, 0)
    }
    
    
    private func _hashCountScan(_ key:String, keywords:String?) async throws -> Int {
        if isMatchAll(keywords ?? "") {
            logger.info("keywords is match all, use hlen...")
            return try await _hlen(key)
        }
        
        var cursor:Int = 0
        var count:Int = 0
        
        while true {
            let res = await _hscanCount(key, keywords: keywords, cursor: cursor, count: dataCountScanCount)
            logger.info("loop scan page, current cursor: \(cursor), total count: \(count)")
            cursor = res.0
            count = count + res.1
            
            // 取到结果，或者已满足分页数据
            if cursor == 0{
                break
            }
        }
        return count
    }
    
    private func _hashPageScan(_ key:String, page: Page) async throws -> [(String, String?)] {
        let keywords = page.keywords.isEmpty ? nil : page.keywords
        var end:Int = page.end
        var cursor:Int = 0
        var keys:[(String, String?)] = []
        
        while true {
            let res = try await _hscan(key, keywords: keywords, cursor: cursor, count: dataScanCount)
            logger.info("hash loop scan page, current cursor: \(cursor), total count: \(keys.count)")
            cursor = res.0
            keys = keys + res.1
            
            // 取到结尾，或者已满足分页数据
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
    
    
    private func _hlen(_ key:String) async throws -> Int {
        let command: RedisCommand<Int> = .hlen(of: RedisKey(key))
        return await _send(command, -1)
    }
    
    
    private func _hscanCount(_ key:String, keywords:String?, cursor:Int, count:Int = 100) async -> (Int, Int) {
        logger.debug("redis hash scan, key: \(key) cursor: \(cursor), keywords: \(String(describing: keywords)), count:\(String(describing: count))")
        
        let r = await _hscan(key, keywords: keywords, cursor: cursor, count: count)
        return (r.0, r.1.count)
    }
    
    private func _hscan(_ key:String, keywords:String?, cursor:Int, count:Int = 100) async -> (Int, [(String, String?)]) {
        logger.debug("redis hash scan, key: \(key) cursor: \(cursor), keywords: \(String(describing: keywords)), count:\(String(describing: count))")
        
        let command: RedisCommand<(Int, [(String, String?)])> = ._hscan(key, keywords: keywords, cursor: cursor, count: count)
        return await _send(command, (0, []))
    }
    
    private func _hget(_ key:String, field:String) async -> String? {
        let command: RedisCommand<String?> = .hget(key, field: field)
        return await _send(command, "")
    }
}
