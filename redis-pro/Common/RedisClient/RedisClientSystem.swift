//
//  RedisClientSystem.swift
//  redis-pro
//
//  Created by chengpan on 2022/3/6.
//

import Foundation
import RediStack

// system
extension RediStackClient {
    
    func selectDB(_ database: Int) async -> Bool {
        do {
            let conn = try await getConn()
            return try await withCheckedThrowingContinuation { continuation in
                
                conn.select(database: database)
                    .whenComplete({completion in
                        if case .success(let r) = completion {
                            self.logger.info("select redis database: \(database), r: \(r)")
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
    
    func databases() async -> Int {
        do {
            let conn = try await getConn()
            return try await withCheckedThrowingContinuation { continuation in
                
                conn.send(command: "CONFIG", with: [RESPValue(from: "GET"), RESPValue(from: "databases")])
                    .whenComplete({completion in
                        if case .success(let r) = completion {
                            let dbs = r.array
                            self.logger.info("get config databases: \(String(describing: dbs))")
                            continuation.resume(returning: NumberHelper.toInt(dbs?[1], defaultValue: 16))
                        }
                        
                        self.complete(completion, continuation: continuation)
                    })
            }
        } catch {
            handleError(error)
        }
        return 0
    }
    
    func dbsize() async -> Int {
        begin()
        defer {
            complete()
        }
        do {
            let conn = try await getConn()
            
            return try await withCheckedThrowingContinuation { continuation in
                
                conn.send(command: "dbsize")
                    .whenComplete({completion in
                        if case .success(let r) = completion {
                            let dbsize = r.int ?? 0
                            self.logger.info("query redis dbsize success: \(dbsize)")
                            continuation.resume(returning: dbsize)
                        }
                        else if case .failure(let error) = completion {
                            self.logger.error("query redis dbsize error: \(error)")
                            continuation.resume(returning: 0)
                        }
                    })
                
            }
        } catch {
            self.logger.error("query redis dbsize error: \(error)")
        }
        return 0
    }
    
    func flushDB() async -> Bool {
        begin()
        defer {
            complete()
        }
        do {
            let conn = try await getConn()
            
            return try await withCheckedThrowingContinuation { continuation in
                
                conn.send(command: "FLUSHDB")
                    .whenComplete({completion in
                        if case .success(let r) = completion {
                            self.logger.info("flush db success: \(r)")
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
    
    func clientKill(_ clientModel:ClientModel) async -> Bool {
        begin()
        defer {
            complete()
        }
        do {
            let conn = try await getConn()
            
            return try await withCheckedThrowingContinuation { continuation in
                
                conn.send(command: "CLIENT", with: [RESPValue(from: "KILL"), RESPValue(from: "\(clientModel.addr)")])
                    .whenComplete({completion in
                        if case .success(let r) = completion {
                            self.logger.info("flush db success: \(r)")
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
    
    func clientList() async -> [ClientModel] {
        begin()
        defer {
            complete()
        }
        do {
            let conn = try await getConn()
            
            return try await withCheckedThrowingContinuation { continuation in
                
                conn.send(command: "CLIENT", with: [RESPValue(from: "LIST")])
                    .whenComplete({completion in
                        if case .success(let r) = completion {
                            self.logger.info("query redis server client list success: \(r)")
                            let resStr = r.string ?? ""
                            let lines = resStr.components(separatedBy: "\n")
                            
                            var resArray = [ClientModel]()
                            
                            lines.forEach({ line in
                                if !line.contains("=") {
                                    return
                                }
                                resArray.append(ClientModel(line: line))
                            })

                            continuation.resume(returning: resArray)
                        }
                        self.complete(completion, continuation: continuation)
                    })
                
            }
        } catch {
            handleError(error)
        }
        return []
    }
    
    func info() async -> [RedisInfoModel] {
        begin()
        defer {
            complete()
        }
        do {
            let conn = try await getConn()
            
            return try await withCheckedThrowingContinuation { continuation in
                
                conn.send(command: "info")
                    .whenComplete({completion in
                        if case .success(let r) = completion {
                            self.logger.info("query redis server info success: \(r.string ?? "")")
                            let infoStr = r.string ?? ""
                            let lines = infoStr.components(separatedBy: "\n")
                            
                            var redisInfoModels = [RedisInfoModel]()
                            var item:RedisInfoModel?
                            
                            lines.forEach({ line in
                                if line.starts(with: "#") {
                                    if item != nil {
                                        redisInfoModels.append(item!)
                                    }
                                    
                                    let section = line.replacingOccurrences(of: "#", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                                    item = RedisInfoModel(section: section)
                                }
                                if line.contains(":") {
                                    let infoArr = line.components(separatedBy: ":")
                                    let redisInfoItemModel = RedisInfoItemModel(section: item?.section ?? "", key: infoArr[0].trimmingCharacters(in: .whitespacesAndNewlines), value: infoArr[1].trimmingCharacters(in: .whitespacesAndNewlines))
                                    item?.infos.append(redisInfoItemModel)
                                }
                            })
                            continuation.resume(returning: redisInfoModels)
                        }
                        self.complete(completion, continuation: continuation)
                    })
                
            }
        } catch {
            handleError(error)
        }
        return []
    }
    
    func resetState() async -> Bool {
        logger.info("reset state...")

        do {
            let conn = try await getConn()
            
            return try await withCheckedThrowingContinuation { continuation in
                
                conn.send(command: "CONFIG", with: [RESPValue(from: "RESETSTAT")])
                    .whenComplete({completion in
                        if case .success(let r) = completion {
                            self.logger.info("reset state res: \(r)")
                            continuation.resume(returning: r.string == "OK")
                        }
                        self.complete(completion, continuation: continuation)
                    })
                
            }
        } catch {
            handleError(error)
        }
        return false
    }
    
    func ping() async -> Bool {
        begin()
    
        do {
            let conn = try await getConn()
            
            return try await withCheckedThrowingContinuation { continuation in
                conn.ping().whenComplete({completion in
                    if case .success(let pong) = completion {
                        continuation.resume(returning: "PONG".caseInsensitiveCompare(pong) == .orderedSame)
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
