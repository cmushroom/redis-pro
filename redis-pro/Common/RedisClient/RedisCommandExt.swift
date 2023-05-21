//
//  RedisCommandExt.swift
//  redis-pro
//
//  Created by chengpan on 2022/7/31.
//

import Logging
import Foundation
import RediStack

private let logger: Logger = Logger(label: "redis-command")


// MARK: - Bool
extension RedisCommand where ResultType == Bool {
    
    public static func flushDB() -> RedisCommand<Bool> {
        return .init(keyword: "FLUSHDB", arguments: [], mapValueToResult: {
            $0.string == "OK"
        })
    }
    

    public static func clientKill(_ addr:String) -> RedisCommand<Bool> {
        return .init(keyword: "CLIENT", arguments: [.init(from: "KILL"), .init(from: addr)], mapValueToResult: {
            $0.string == "OK"
        })
    }
    
    public static func resetState() -> RedisCommand<Bool> {
        return .init(keyword: "CONFIG", arguments: [.init(from: "RESETSTAT")], mapValueToResult: {
            $0.string == "OK"
        })
    }
    
    public static func configRewrite() -> RedisCommand<Bool> {
        return .init(keyword: "CONFIG", arguments: [.init(from: "REWRITE")], mapValueToResult: {
            $0.string == "OK"
        })
    }
    
    public static func setConfig(_ key:String, value:String ) -> RedisCommand<Bool> {
        return .init(keyword: "CONFIG", arguments: [.init(from: "SET"), .init(from: key), .init(from: value)], mapValueToResult: {
            $0.string == "OK"
        })
    }
    
    public static func slowlogReset() -> RedisCommand<Bool> {
        return .init(keyword: "SLOWLOG", arguments: [.init(from: "RESET")], mapValueToResult: {
            $0.string == "OK"
        })
    }
}


// MARK: - String optional
extension RedisCommand where ResultType == String? {
    @usableFromInline
    internal init(keyword: String, arguments: [RESPValue]) {
        self.init(keyword: keyword, arguments: arguments, mapValueToResult: {
            switch $0 {
            case let .simpleString(buffer),
                 let .bulkString(.some(buffer)):
                guard let value = String(fromRESP: $0) else { return "\(buffer)" } // default to ByteBuffer's representation
                return value

            // .integer, .error, and .bulkString(.none) conversions to String always succeed
            case .integer,
                 .bulkString(.none):
                return String(fromRESP: $0)!
                
            case .null, .error: return nil
            case let .array(elements): return "[\(elements.map({ $0.description }).joined(separator: ","))]"
            }
        })
    }
    
    public static func hget(_ key: String, field:String) -> RedisCommand<String?> {
        return .init(keyword: "HGET", arguments: [.init(from: key), .init(from: field)])
    }
}

// MARK: - String
extension RedisCommand where ResultType == String {
    @usableFromInline
    internal init(keyword: String, arguments: [RESPValue]) {
        self.init(keyword: keyword, arguments: arguments, mapValueToResult: {
            return $0.description
        })
    }
    
    public static func getRange(_ key: String, start:Int = 0, end:Int) -> RedisCommand<String> {
        return .init(keyword: "GETRANGE", arguments: [.init(from: key), .init(from: start), .init(from: end)])
    }
    
    public static func type(_ key: String) -> RedisCommand<String> {
        return .init(keyword: "TYPE", arguments: [.init(from: key)])
    }
    
    public static func getConfig(_ key: String) -> RedisCommand<String> {
        return .init(keyword: "CONFIG", arguments: [.init(from: "GET"), .init(from: key)])
    }
}

// MARK: - Int
extension RedisCommand where ResultType == Int {
    public static func renamenx(_ key: String, newKey:String) -> RedisCommand<Int> {
        return .init(keyword: "RENAMENX", arguments: [.init(from: key), .init(from: newKey)])
    }
    
    
    public static func databases() -> RedisCommand<Int> {
        return .init(keyword: "CONFIG", arguments: [.init(from: "GET"), .init(from: "databases")], mapValueToResult: {
            let dbs = $0.array
            return NumberHelper.toInt(dbs?[1], defaultValue: 16)
        })
    }
    
    public static func dbsize() -> RedisCommand<Int> {
        return .init(keyword: "DBSIZE", arguments: [], mapValueToResult: {
            $0.int ?? 0
        })
    }
    
    public static func slowlogLen() -> RedisCommand<Int> {
        return .init(keyword: "SLOWLOG", arguments: [.init(from: "LEN")], mapValueToResult: {
            $0.int ?? 0
        })
    }
}


// MARK: - Hash
extension RedisCommand where ResultType == (Int, [(String, String?)]) {
    public static func _hscan(_ key: String, keywords:String?, cursor:Int, count:Int = 100) -> RedisCommand<(Int, [(String, String?)])> {
        var args: [RESPValue] = [.init(from: key), .init(from: cursor)]

        if let m = keywords {
            args.append(.init(from: "MATCH"))
            args.append(.init(from: m))
        }
        
        args.append(.init(from: "COUNT"))
        args.append(.init(from: count))
        
        return .init(keyword: "HSCAN", arguments: args, mapValueToResult: { r in
            guard let scanR:[RESPValue] = r.array else {
                return (0, [])
            }
            
            let cursor = Int(scanR[0].string!) ?? 0
            
            let elements:[(String, String?)] = _mapRes(scanR[1].array)
            return (cursor, elements)
        })
    }
    
    static func _mapRes(_ values: [RESPValue]?) -> [(String, String?)]{
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
}



// MARK: - Client
extension RedisCommand where ResultType == [ClientModel] {
    
    public static func clientList() -> RedisCommand<[ClientModel]> {
        return .init(keyword: "CLIENT", arguments: [.init(from: "LIST")], mapValueToResult: { r in
            let resStr = r.string ?? ""
            let lines = resStr.components(separatedBy: "\n")
            
            var resArray = [ClientModel]()
            
            lines.forEach({ line in
                if !line.contains("=") {
                    return
                }
                resArray.append(ClientModel(line: line))
            })
            return resArray
        })
    }
}


// MARK: - Info
extension RedisCommand where ResultType == [RedisInfoModel] {
    public static func info() -> RedisCommand<[RedisInfoModel]> {
        return self.init(keyword: "INFO", arguments: [], mapValueToResult: { r in
            //            self.logger.info("query redis server info success: \(r.string ?? "")")
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
                } })
            
            return redisInfoModels
        })
    }
}



// MARK: - Config
extension RedisCommand where ResultType == [RedisConfigItemModel] {
    public static func configList(_ pattern: String = "*") -> RedisCommand<[RedisConfigItemModel]> {
        var _pattern = pattern
        if pattern.isEmpty {
            _pattern = "*"
        }
        
        return self.init(keyword: "CONFIG", arguments: [.init(from: "GET"), .init(from: _pattern)], mapValueToResult: { r in
            
            logger.info("get redis config list res: \(r)")
            let configs = r.array ?? []
            
            var configList = [RedisConfigItemModel]()
            
            let max:Int = configs.count / 2
            
            for index in (0..<max) {
                configList.append(RedisConfigItemModel(key: configs[ index * 2].string, value: configs[index * 2 + 1].string))
            }
            
            return configList
        })
    }
}


// MARK: - Slowlog
extension RedisCommand where ResultType == [SlowLogModel] {
    public static func slowlogList(_ size:Int) -> RedisCommand<[SlowLogModel]> {
    
        return self.init(keyword: "SLOWLOG", arguments: [.init(from: "GET"), .init(from: size)], mapValueToResult: { r in
            
            logger.info("get slow log res: \(r)")
            
            var slowLogs = [SlowLogModel]()
            r.array?.forEach({ item in
                let itemArray = item.array
                
                let cmd = itemArray?[3].array!.map({
                    $0.string ?? MTheme.NULL_STRING
                }).joined(separator: " ")
                
                slowLogs.append(SlowLogModel(id: itemArray?[0].string, timestamp: itemArray?[1].int, execTime: itemArray?[2].string, cmd: cmd, client: itemArray?[4].string, clientName: itemArray?[5].string))
            })
            return slowLogs
        })
    }
}
