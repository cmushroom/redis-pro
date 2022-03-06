//
//  RedisClientSlowLog.swift
//  redis-pro
//
//  Created by chengpan on 2022/3/6.
//

import Foundation
import RediStack

// slow log
extension RediStackClient {
    func slowLogReset() async -> Bool {
        logger.info("slow log reset ...")
        
        do {
            let conn = try await getConn()
            
            return try await withCheckedThrowingContinuation { continuation in
                conn.send(command: "SLOWLOG", with: [RESPValue(from: "RESET")])
                    .whenComplete({completion in
                    if case .success(let r) = completion {
                        self.logger.info("slow log reset res: \(r)")
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
    
    func slowLogLen() async -> Int {
        logger.info("get slow log len ...")
        do {
            let conn = try await getConn()
            
            return try await withCheckedThrowingContinuation { continuation in
                conn.send(command: "SLOWLOG", with: [RESPValue(from: "LEN")])
                    .whenComplete({completion in
                    if case .success(let r) = completion {
                        self.logger.info("slow log reset res: \(r)")
                        continuation.resume(returning: r.int ?? 0)
                    }
                    self.complete(completion, continuation:continuation)
                })
            }
        } catch {
            handleError(error)
        }
        
        return 0
        
    }
    
    func getSlowLog(_ size:Int) async -> [SlowLogModel] {
        logger.info("get slow log list ...")
        
        begin()
        defer {
            complete()
        }
        do {
            let conn = try await getConn()
            
            return try await withCheckedThrowingContinuation { continuation in
                conn.send(command: "SLOWLOG", with: [RESPValue(from: "GET"), RESPValue(from: size)])
                    .whenComplete({completion in
                    if case .success(let r) = completion {
                        self.logger.info("get slow log res: \(r)")
                        
                        var slowLogs = [SlowLogModel]()
                        r.array?.forEach({ item in
                            let itemArray = item.array
                            
                            let cmd = itemArray?[3].array!.map({
                                $0.string ?? MTheme.NULL_STRING
                            }).joined(separator: " ")
                            
                            slowLogs.append(SlowLogModel(id: itemArray?[0].string, timestamp: itemArray?[1].int, execTime: itemArray?[2].string, cmd: cmd, client: itemArray?[4].string, clientName: itemArray?[5].string))
                        })
                        
                        continuation.resume(returning: slowLogs)
                    }
                    self.complete(completion, continuation:continuation)
                })
            }
        } catch {
            handleError(error)
        }
        
        return []
    }
}

