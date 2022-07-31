//
//  RedisClientLua.swift
//  redis-pro
//
//  Created by chengpan on 2022/7/17.
//

import Foundation
import RediStack

// lua script
extension RediStackClient {
    func eval(_ lua:String) async -> String {
        logger.info("lua script eval: \(lua)")
        guard lua.count > 3 else {
            return "lua script invalid!"
        }
        begin()
        defer {
            complete()
        }
        
        do {
            let lua = StringHelper.trim(StringHelper.removeStartIgnoreCase(lua, start: "eval"))
            if !StringHelper.startWith(lua, start: "'") && !StringHelper.startWith(lua, start: "\"") {
                throw BizError("lua script syntax error, demo: \"return {KEYS[1],KEYS[2],ARGV[1],ARGV[2]}\" 2 key1 key2 arg1 arg2")
            }
            
            
            let separator = lua[0]
            let scriptLastIndex = lua.lastIndexOf(separator)!
            let start = lua.index(lua.startIndex, offsetBy: 1)
            let script = String(lua[start..<scriptLastIndex])
            
            let argStart = lua.index(scriptLastIndex, offsetBy: 1)
            let args = StringHelper.trim(String(lua[argStart...]))
            
            let argArr = StringHelper.split(args)
            
            logger.info("eval lua script, script: \(script), args: \(argArr)")
            
            var respValues = argArr.map { RESPValue(from: $0) }
            respValues.insert(RESPValue(from: script), at: 0)
            
            
            let conn = try await getConn()
            
            return try await withCheckedThrowingContinuation { continuation in
                conn.send(command: "EVAL", with: respValues)
                    .whenComplete({completion in
                        if case .success(let r) = completion {
                            self.logger.info("lua script eval r: \(r)")
                            continuation.resume(returning: r.description)
                        }
                        self.complete(completion, continuation:continuation)
                    })
            }
        } catch {
            handleError(error)
        }
        
        return "eval error"
    }
    
    
    func scriptLoad(_ lua:String) async -> String {
        logger.info("lua script load: \(lua)")
        guard lua.count > 3 else {
            return "lua script invalid!"
        }
        
        do {
            let lua = StringHelper.trim(StringHelper.removeStartIgnoreCase(lua, start: "eval"))
            if !StringHelper.startWith(lua, start: "'") && !StringHelper.startWith(lua, start: "\"") {
                throw BizError("lua script syntax error, demo: \"return {KEYS[1],KEYS[2],ARGV[1],ARGV[2]}\" 2 key1 key2 arg1 arg2")
            }

            let conn = try await getConn()
            
            return try await withCheckedThrowingContinuation { continuation in
                conn.send(command: "SCRIPT", with: [RESPValue(from: "LOAD"), RESPValue(from: lua)])
                    .whenComplete({completion in
                        if case .success(let r) = completion {
                            self.logger.info("lua script eval r: \(r)")
                            continuation.resume(returning: r.description)
                        }
                        self.complete(completion, continuation:continuation)
                    })
            }
        } catch {
//            handleError(error)
        }
        
        return "-"
    }
    
    
    
    func scriptKill() async -> String {
        logger.info("lua script kill")

        do {

            let conn = try await initConn()
            defer {
                conn.close()
                complete()
            }
            
            return try await withCheckedThrowingContinuation { continuation in
                conn.send(command: "SCRIPT", with: [RESPValue(from: "KILL")])
                    .whenComplete({completion in
                        if case .success(let r) = completion {
                            self.logger.info("lua script kill r: \(r)")
                            Messages.show("Script Kill Complete, \(r.string ?? "")!")
                            continuation.resume(returning: r.string ?? "")
                        }
                        self.complete(completion, continuation:continuation)
                    })
            }
        } catch {
            handleError(error)
        }
        
        return "-"
    }
    
    
    
    func scriptFlush() async -> Void {
        logger.info("lua script flush")

        do {

            let conn = try await getConn()
            defer {
                complete()
            }
            
            return try await withCheckedThrowingContinuation { continuation in
                conn.send(command: "SCRIPT", with: [RESPValue(from: "FLUSH")])
                    .whenComplete({completion in
                        if case .success(let r) = completion {
                            self.logger.info("lua script flush r: \(r)")
                            Messages.show("Script flush Result: \(r.string ?? "")!")
                            continuation.resume()
                        }
                        self.complete(completion, continuation:continuation)
                    })
            }
        } catch {
            handleError(error)
        }
    }
}

