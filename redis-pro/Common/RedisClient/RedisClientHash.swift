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
                
                let pageData:[(String, String?)] = try await hashPageScan(key, page: page)
                r = pageData.map({
                    RedisHashEntryModel(field: $0.0, value: $0.1)
                })
                
                let total = try await hashCountScan(key, keywords: match)
                page.total = total
            } else {
                let value = try await hashGet(key, field: page.keywords)
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
    
    
    private func hashCountScan(_ key:String, keywords:String?) async throws -> Int {
        if isMatchAll(keywords ?? "") {
            logger.info("keywords is match all, use hlen...")
            return try await hlen(key)
        }
        
        var cursor:Int = 0
        var count:Int = 0
        
        while true {
            let res = try await hscanCount(key, keywords: keywords, cursor: cursor, count: dataCountScanCount)
            logger.info("loop scan page, current cursor: \(cursor), total count: \(count)")
            cursor = res.0
            count = count + (res.1 / 2)
            
            // 取到结果，或者已满足分页数据
            if cursor == 0{
                break
            }
        }
        return count
    }
    
    private func hashPageScan(_ key:String, page: Page) async throws -> [(String, String?)] {
        let keywords = page.keywords.isEmpty ? nil : page.keywords
        var end:Int = page.end
        var cursor:Int = 0
        var keys:[(String, String?)] = []
        
        while true {
            let res = try await hscan(key, keywords: keywords, cursor: cursor, count: dataScanCount)
            logger.info("hash loop scan page, current cursor: \(cursor), total count: \(keys.count)")
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
        return Array(keys[start..<end])
        
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
    
    
    private func hscanCount(_ key:String, keywords:String?, cursor:Int, count:Int = 100) async throws -> (Int, Int) {
        logger.debug("redis hash scan, key: \(key) cursor: \(cursor), keywords: \(String(describing: keywords)), count:\(String(describing: count))")
        
        let conn = try await getConn()
        return try await withCheckedThrowingContinuation { continuation in

            var args: [RESPValue] = [.init(from: key), .init(from: cursor)]

            if let m = keywords {
                args.append(.init(from: "MATCH"))
                args.append(.init(from: m))
            }
            
            args.append(.init(from: "COUNT"))
            args.append(.init(from: count))
      
            conn.send(command: "HSCAN", with: args).whenComplete({completion in
                if case .success(let r) = completion {
                    self.logger.error("redis hash scan r: \(r)")
                    guard let scanR:[RESPValue] = r.array else {
                        continuation.resume(returning: (0, 0))
                        return
                    }
                    
                    let cursor = Int(scanR[0].string!) ?? 0
                    
                    continuation.resume(returning: (cursor, scanR[1].array?.count ?? 0))
                }
                else if case .failure(let error) = completion {
                    self.logger.error("redis hash scan error: \(error)")
                    continuation.resume(throwing: error)
                }
            })
        }
    }
    
    private func hscan(_ key:String, keywords:String?, cursor:Int, count:Int = 100) async throws -> (Int, [(String, String?)]) {
        logger.debug("redis hash scan, key: \(key) cursor: \(cursor), keywords: \(String(describing: keywords)), count:\(String(describing: count))")
        
        let conn = try await getConn()
        return try await withCheckedThrowingContinuation { continuation in

            var args: [RESPValue] = [.init(from: key), .init(from: cursor)]

            if let m = keywords {
                args.append(.init(from: "MATCH"))
                args.append(.init(from: m))
            }
            
            args.append(.init(from: "COUNT"))
            args.append(.init(from: count))
      
            conn.send(command: "HSCAN", with: args).whenComplete({completion in
                if case .success(let r) = completion {
                    guard let scanR:[RESPValue] = r.array else {
                        continuation.resume(returning: (0, []))
                        return
                    }
                    
                    let cursor = Int(scanR[0].string!) ?? 0
                    
                    continuation.resume(returning: (cursor, self.mapRes(scanR[1].array)))
                }
                else if case .failure(let error) = completion {
                    self.logger.error("redis hash scan error: \(error)")
                    continuation.resume(throwing: error)
                }
            })
        }
    }
    
    private func mapRes(_ values: [RESPValue]?) -> [(String, String?)]{
        guard let values = values else { return [] }
        guard values.count > 0 else { return [] }

        var result: [(String, String?)] = []

        var index = 0
        repeat {
            result.append((values[index].string!, values[index + 1].string))
            index += 2
        } while (index < values.count)
        
        return result
    }
    
    func hget(_ key:String, field:String) async -> String {
        logger.info("get hash field value, key:\(key), field: \(field)")
        begin()
 
        do {
            return try await hashGet(key, field: field) ?? ""
        } catch {
            handleError(error)
        }
        return Cons.EMPTY_STRING
    }
    
    private func hashGet(_ key:String, field:String) async throws -> String? {
        let conn = try await getConn()
        
        return try await withCheckedThrowingContinuation { continuation in
            
            conn.hget(field, from: RedisKey(key))
                .whenComplete({completion in
                    if case .success(let r) = completion {
                        self.logger.info("hget value key: \(key), field: \(field) complete, r: \(r)")
                        continuation.resume(returning: r.string)
                    }
                    
                    self.complete(completion, continuation: continuation)
                })
            
        }
    }
}
