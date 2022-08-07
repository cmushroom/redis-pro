//
//  RedisClientSlowLog.swift
//  redis-pro
//
//  Created by chengpan on 2022/3/6.
//

import Foundation
import RediStack

// MARK: -slow log
extension RediStackClient {
    func slowLogReset() async -> Bool {
        logger.info("slow log reset ...")
        let command: RedisCommand<Bool> = .slowlogReset()
        return await send(command, false)
        
    }
    
    func slowLogLen() async -> Int {
        logger.info("get slow log len ...")
        let command: RedisCommand<Int> = .slowlogLen()
        return await send(command, 0)
    }
    
    func getSlowLog(_ size:Int) async -> [SlowLogModel] {
        logger.info("get slow log list ...")
        let command: RedisCommand<[SlowLogModel]> = .slowlogList(size)
        return await send(command, [])
    }
}

