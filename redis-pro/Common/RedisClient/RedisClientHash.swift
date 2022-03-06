//
//  RedisClientHash.swift
//  redis-pro
//
//  Created by chengpan on 2022/3/6.
//

import Foundation
import RediStack

// hash
extension RediStackClient {
    
    // hash operator
    
    func pageHash(_ key:String, page:ScanModel) async -> [RedisHashEntryModel] {
        logger.info("redis hash field page scan, key: \(key), page: \(page)")
        
        begin()
        defer {
            complete()
        }
        do {
            let match = page.keywords.isEmpty ? nil : page.keywords
            
            let cursor:Int = page.cursor
            let fields:[(String, String?)] = []
            
            let res = try await recursionHScan(key, keywords: match, cursor: cursor, maxCount: page.size, fields: fields)
            
            page.cursor = res.0
            
            let pageData:[(String, String?)] = res.1
            let r:[RedisHashEntryModel] = pageData.sorted(by: {$0.0 > $1.0}).map({
                RedisHashEntryModel(field: $0.0, value: $0.1)
            })
            
            let total = try await recursionHScanTotal(key, keywords: match)
            page.total = total
            
            return r
        } catch {
            handleError(error)
        }
        return []
    }
    
    func hset(_ key:String, field:String, value:String) async -> Bool {
        logger.info("redis hash hset key:\(key), field:\(field), value:\(value)")
        begin()
 
        do {
            let conn = try await getConn()
            
            return try await withCheckedThrowingContinuation { continuation in
                
                conn.hset(field, to: value, in: RedisKey(key))
                    .whenComplete({completion in
                        if case .success(let r) = completion {
                            self.logger.info("hset success, key:\(key), field:\(field), value:\(value), r:\(r)")
                            continuation.resume(returning: true)
                        }
                        
                        self.complete(completion, continuation: continuation)
                    })
                
            }
        } catch {
            handleError(error)
        }
        return false
    }
    
    func hdel(_ key:String, field:String) async -> Int {
        logger.info("redis hash hdel key:\(key), field:\(field)")
        begin()
 
        do {
            let conn = try await getConn()
            
            return try await withCheckedThrowingContinuation { continuation in
                
                conn.hdel(field, from: RedisKey(key))
                    .whenComplete({completion in
                        if case .success(let r) = completion {
                            self.logger.info("hdel success, key:\(key), field:\(field)")
                            continuation.resume(returning: r)
                        }
                        
                        self.complete(completion, continuation: continuation)
                    })
                
            }
        } catch {
            handleError(error)
        }
        return 0
        
    }
    
    // 递归取出包含分页的数据
    private func recursionHScan(_ key:String, keywords:String?, cursor:Int, maxCount:Int, fields:[(String, String?)]) async throws -> (Int, [(String, String?)]) {
        if fields.count >= maxCount {
            self.logger.info("recursion scan get keys enough, max count: \(maxCount), current count: \(fields.count)")
            return (cursor, fields)
        } else {
            let res = try await hscan(key, keywords: keywords, cursor: cursor, count: maxCount)
            
            let newFields:[(String, String?)] = fields + res.1.map{$0}
            
            if res.0 == 0 {
                self.logger.info("recursion hscan reach end, max count: \(maxCount), current count: \(newFields.count)")
                
                return (res.0, newFields)
            }
            
            self.logger.info("recursion hscan get more keys, current count: \(newFields.count)")
            return try await recursionHScan(key, keywords: keywords, cursor: res.0, maxCount: maxCount, fields: newFields)
        }
    }
    
    private func hscanTotal(_ key:String, keywords:String?, cursor:Int, total:Int) async throws -> Int {
        let res = try await hscan(key, keywords: keywords, cursor: cursor, count: 1000)
        let newTotal:Int = total + res.1.count
        if res.0 == 0 {
            self.logger.info("recursion scan total reach end, total: \(newTotal)")
            
            return newTotal
        }
        
        self.logger.info("recursion scan total get more, current total: \(newTotal)")
        return try await hscanTotal(key, keywords: keywords, cursor: res.0, total: newTotal)
    }
    
    private func recursionHScanTotal(_ key:String, keywords:String?) async throws -> Int {
        if isMatchAll(keywords) {
            logger.info("hscan total key: \(key), keywords is match all, use hlen...")
            return try await hlen(key)
        }
        
        let cursor:Int = 0
        let total:Int = 0
        
        return try await hscanTotal(key, keywords: keywords, cursor: cursor, total: total)
    }
    
    private func hlen(_ key:String) async throws -> Int {
        let conn = try await getConn()
        return try await withCheckedThrowingContinuation { continuation in
            
            conn.hlen(of: RedisKey(key))
                .whenComplete({completion in
                    if case .success(let r) = completion {
                        continuation.resume(returning: r)
                    }
                    else if case .failure(let error) = completion {
                        self.logger.error("redis hash hlen error \(error)")
                        continuation.resume(throwing: error)
                    }
                })
            
        }
    }
    
    private func hscan(_ key:String, keywords:String?, cursor:Int, count:Int? = 1) async throws -> (Int, [String: String?]) {
        logger.debug("redis hash scan, key: \(key) cursor: \(cursor), keywords: \(String(describing: keywords)), count:\(String(describing: count))")
        
        let conn = try await getConn()
        return try await withCheckedThrowingContinuation { continuation in
            
            conn.hscan(RedisKey(key), startingFrom: cursor, matching: keywords, count: count, valueType: String.self)
                .whenComplete({completion in
                    if case .success(let r) = completion {
                        continuation.resume(returning: r)
                    }
                    else if case .failure(let error) = completion {
                        self.logger.error("redis hash scan error \(error)")
                        continuation.resume(throwing: error)
                    }
                })
            
        }
    }
    
    func hget(_ key:String, field:String) async -> String {
        logger.info("get hash field value, key:\(key), field: \(field)")
        begin()
 
        do {
            let conn = try await getConn()
            
            return try await withCheckedThrowingContinuation { continuation in
                
                conn.hget(field, from: RedisKey(key))
                    .whenComplete({completion in
                        if case .success(let r) = completion {
                            self.logger.info("hget value key: \(key), field: \(field) complete, r: \(r)")
                            continuation.resume(returning: r.string!)
                        }
                        
                        self.complete(completion, continuation: continuation)
                    })
                
            }
        } catch {
            handleError(error)
        }
        return Cons.EMPTY_STRING
    }
}
