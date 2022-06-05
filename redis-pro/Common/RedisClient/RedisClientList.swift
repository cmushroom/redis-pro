//
//  RedisClientList.swift
//  redis-pro
//
//  Created by chengpan on 2022/3/6.
//

import Foundation
import RediStack

// list
extension RediStackClient {

    func pageList(_ key:String, page:Page) async -> [RedisListItemModel] {
        
        logger.info("redis list page, key: \(key), page: \(page)")
        begin()
        defer {
            complete()
        }
        do {
            let start:Int = (page.current - 1) * page.size
            let r1 = try await llen(key)
            let r2 = try await lrange(key, start: start, stop: start + page.size - 1)
            let total = r1
            page.total = total
            
            var result:[RedisListItemModel] = []
            
            for (index, value) in r2.enumerated() {
                result.append(RedisListItemModel(start + index, value ?? ""))
            }
     
            return result
        } catch {
            handleError(error)
        }
        return []
    }
    
    private func lrange(_ key:String, start:Int, stop:Int) async throws -> [String?] {
        
        logger.debug("redis list range, key: \(key)")
        
        let conn = try await getConn()
        
        return try await withCheckedThrowingContinuation { continuation in
            
            conn.lrange(from: RedisKey(key), firstIndex: start, lastIndex: stop, as: String.self)
                .whenComplete({completion in
                    if case .success(let r) = completion {
                        continuation.resume(returning: r)
                    }
                    
                    else if case .failure(let error) = completion {
                        self.logger.error("redis list range error \(error)")
                        continuation.resume(throwing: error)
                    }
                })
        }
    }
    
    func ldel(_ key:String, index:Int, value:String) async -> Int {
        logger.debug("redis list delete, key: \(key), index:\(index)")
        
        begin()
        defer {
            complete()
        }
        
        do {
            let existValue = try await _lindex(key, index: index)
            guard existValue == value else {
                throw BizError("list value: \(value), index: \(index) have changed, please check!")
            }
            
            try await _lset(key, index: index, value: Constants.LIST_VALUE_DELETE_MARK)
            
            return try await _lrem(key,value: Constants.LIST_VALUE_DELETE_MARK)
        } catch {
            handleError(error)
        }
        return 0
    }
    
    
    private func _lrem(_ key:String, value:String) async throws -> Int {
        let conn = try await getConn()
        return try await withCheckedThrowingContinuation { continuation in
            
            conn.lrem(value, from: RedisKey(key), count: 0)
                .whenComplete({completion in
                    if case .success(let r) = completion {
                        continuation.resume(returning: r)
                    }
                    
                    self.complete(completion, continuation: continuation)
                })
        }
    }
    
    func lset(_ key:String, index:Int, value:String) async -> Void {
        begin()
        defer {
            complete()
        }
        do {
            try await _lset(key, index: index, value: value)
        } catch {
            handleError(error)
        }
    }
    
    private func _lset(_ key:String, index:Int, value:String) async throws -> Void {
        let conn = try await getConn()
        
        return try await withCheckedThrowingContinuation { continuation in
            
            conn.lset(index: index, to: value, in: RedisKey(key))
                .whenComplete({completion in
                    if case .success(let r) = completion {
                        continuation.resume(returning: r)
                    }
                    
                    else if case .failure(let error) = completion {
                        self.logger.error("redis list lset error \(error)")
                        continuation.resume(throwing: error)
                    }
                })
        }
    }
    
    func lpush(_ key:String, value:String) async -> Int {
        begin()
        defer {
            complete()
        }
        
        do {
            let conn = try await getConn()
            return try await withCheckedThrowingContinuation { continuation in
                
                conn.lpush(value, into: RedisKey(key))
                    .whenComplete({completion in
                        if case .success(let r) = completion {
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
    
    func rpush(_ key:String, value:String) async -> Int {
        begin()
        defer {
            complete()
        }
        
        do {
            let conn = try await getConn()
            return try await withCheckedThrowingContinuation { continuation in
                
                conn.rpush(value, into: RedisKey(key))
                    .whenComplete({completion in
                        if case .success(let r) = completion {
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
    
    private func _lindex(_ key:String, index:Int) async throws -> String? {
        let conn = try await getConn()
        return try await withCheckedThrowingContinuation { continuation in
            
            conn.lindex(index, from: RedisKey(key))
                .whenComplete({completion in
                    if case .success(let r) = completion {
                        continuation.resume(returning: r.string)
                    }
                    
                    self.complete(completion, continuation: continuation)
                })
        }
    }
    
    private func llen(_ key:String) async throws -> Int {
        logger.debug("redis list length, key: \(key)")
        let conn = try await getConn()
        
        return try await withCheckedThrowingContinuation { continuation in
            
            conn.llen(of: RedisKey(key))
                .whenComplete({completion in
                    if case .success(let r) = completion {
                        continuation.resume(returning: r)
                    }
                    
                    else if case .failure(let error) = completion {
                        self.logger.error("redis list llen error \(error)")
                        continuation.resume(throwing: error)
                    }
                })
        }
    }
}
