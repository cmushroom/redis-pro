//
//  RedisClientSystem.swift
//  redis-pro
//
//  Created by chengpan on 2022/3/6.
//

import Foundation
import RediStack

// MARK: - system function
// system
extension RediStackClient {
    
    func selectDB(_ database: Int) async -> Bool {
        self.logger.info("select db: \(database)")
        self.redisModel.database = database
        
        self.connPool?.close()
        self.connPool = nil
        
        let command: RedisCommand<Void> = .select(database: database)
        let _ = await send(command)
        return true
    }
    
    func databases() async -> Int {
    
        let command: RedisCommand<Int> = .databases()
        return await send(command, 0)
    }
    
    func dbsize() async -> Int {
        
        let command: RedisCommand<Int> = .dbsize()
        return await send(command, 0)
    }
    
    func flushDB() async -> Bool {
        let command: RedisCommand<Bool> = .flushDB()
        return await send(command, false)
    }
    
    func clientKill(_ clientModel:ClientModel) async -> Bool {
        
        let command: RedisCommand<Bool> = .clientKill(clientModel.addr)
        return await send(command, false)
    }
    
    func clientList() async -> [ClientModel] {
        
        let command: RedisCommand<[ClientModel]> = .clientList()
        return await send(command, [])
    }
    
    func info() async -> [RedisInfoModel] {
        let command: RedisCommand<[RedisInfoModel]> = .info()
        return await send(command, [])
    }
    
    func resetState() async -> Bool {
        logger.info("reset state...")
        let command: RedisCommand<Bool> = .resetState()
        return await send(command, false)
    }
    
    func ping() async -> Bool {
        let command: RedisCommand<String> = .ping()
        return await send(command) == "PONG"
    }
    
}
