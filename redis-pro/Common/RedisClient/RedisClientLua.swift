//
//  RedisClientLua.swift
//  redis-pro
//
//  Created by chengpan on 2022/7/17.
//

import Foundation
import RediStack

// MARK: -lua script
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
            
            let command:RedisCommand<String> = RedisCommand(keyword: "EVAL", arguments: respValues, mapValueToResult: {
                $0.description
            })
            return await send(command, "eval error")
        } catch {
            handleError(error)
        }
        
        return "eval error"
    }
    
    
    
    func scriptKill() async -> String {
        logger.info("lua script kill")
        
        
        let command:RedisCommand<String> = RedisCommand(keyword: "SCRIPT", arguments: [.init(from: "KILL")], mapValueToResult: {
            $0.description
        })
        return await send(command, "script kill error")
    }
    
    
    
    func scriptFlush() async -> Void {
        logger.info("lua script flush")
    }
}

