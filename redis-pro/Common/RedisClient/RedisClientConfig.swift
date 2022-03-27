//
//  RedisClientConfig.swift
//  redis-pro
//
//  Created by chengpan on 2022/3/6.
//

import Foundation
import RediStack


// config
extension RediStackClient {
    func getConfigList(_ pattern:String = "*") async -> [RedisConfigItemModel] {
        logger.info("get redis config list, pattern: \(pattern)...")
        begin()
        defer {
            complete()
        }
        
        var _pattern = pattern
        if pattern.isEmpty {
            _pattern = "*"
        }
        
        do {
            let conn = try await getConn()
            
            return try await withCheckedThrowingContinuation { continuation in
                conn.send(command: "CONFIG", with: [RESPValue(from: "GET"), RESPValue(from: _pattern)])
                    .whenComplete({completion in
                    if case .success(let r) = completion {
                        self.logger.info("get redis config list res: \(r)")
                        
                        let configs = r.array ?? []
                        
                        var configList = [RedisConfigItemModel]()
                        
                        let max:Int = configs.count / 2
                        
                        for index in (0..<max) {
                            configList.append(RedisConfigItemModel(key: configs[ index * 2].string, value: configs[index * 2 + 1].string))
                        }
                        
                        continuation.resume(returning: configList)
                    }
                    self.complete(completion, continuation:continuation)
                })
            }
        } catch {
            handleError(error)
        }
        
        return []
    }
    
    func configRewrite() async -> Bool {
        logger.info("redis config rewrite ...")
        begin()
        defer {
            complete()
        }

        do {
            let conn = try await getConn()
            
            return try await withCheckedThrowingContinuation { continuation in
                conn.send(command: "CONFIG", with: [RESPValue(from: "REWRITE")])
                    .whenComplete({completion in
                    if case .success(let r) = completion {
                        self.logger.info("redis config rewrite res: \(r)")
                        continuation.resume(returning: r.string == "OK")
                    }
                    self.complete(completion, continuation:continuation)
                })
            }
        } catch {
            handleError(error)
        }
        
        return false
        
    }
    
    func getConfigOne(key:String) async -> String? {
        logger.info("get redis config ...")
        
        do {
            let conn = try await getConn()
            
            return try await withCheckedThrowingContinuation { continuation in
                conn.send(command: "CONFIG", with: [RESPValue(from: "GET"), RESPValue(from: key)])
                    .whenComplete({completion in
                    if case .success(let r) = completion {
                        self.logger.info("get redis config one res: \(r)")
                        continuation.resume(returning: r.array?[1].string)
                    }
                    self.complete(completion, continuation:continuation)
                })
            }
        } catch {
            handleError(error)
        }
        
        return nil
        
    }
    
    
    func setConfig(key:String, value:String) async -> Bool {
        logger.info("set redis config, key: \(key), value: \(value)")
        begin()
        defer {
            complete()
        }

        do {
            let conn = try await getConn()
            
            return try await withCheckedThrowingContinuation { continuation in
                conn.send(command: "CONFIG", with: [RESPValue(from: "SET"), RESPValue(from: key), RESPValue(from: value)])
                    .whenComplete({completion in
                    if case .success(let r) = completion {
                        self.logger.info("set config res: \(r)")
                        continuation.resume(returning: r.string == "OK")
                    }
                    self.complete(completion, continuation:continuation)
                })
            }
        } catch {
            handleError(error)
        }
        
        return false
    }
    
}
