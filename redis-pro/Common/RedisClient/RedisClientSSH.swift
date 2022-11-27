//
//  RedisClientSSH.swift
//  redis-pro
//
//  Created by chengpan on 2022/8/6.
//

import Foundation
import RediStack
import NIO
import NIOSSH
import Logging

// MARK: -ssh
extension RediStackClient {
    
    func initSSHConn() async throws -> RedisConnection {
        let bindHost = "127.0.0.1"
        
        let sshTunnel = SSHTunnel(sshHost: self.redisModel.sshHost, sshPort: self.redisModel.sshPort, user: self.redisModel.sshUser, pass: self.redisModel.sshPass, targetHost: self.redisModel.host, targetPort: self.redisModel.port)
        let localChannel = try await sshTunnel.openSSHTunnel()
        
        let localBindPort:Int = localChannel.localAddress?.port ?? 0
        self.logger.info("init forwarding server success, local port: \(localBindPort)")
        self.sshLocalChannel = localChannel
        
        return try await initConn(host: bindHost, port: localBindPort, username: self.redisModel.username, pass: self.redisModel.password, database: self.redisModel.database)
    }
    
    
    func initSSHPool() async throws -> RedisConnectionPool {
        let bindHost = "127.0.0.1"
        
        let sshTunnel = SSHTunnel(sshHost: self.redisModel.sshHost, sshPort: self.redisModel.sshPort, user: self.redisModel.sshUser, pass: self.redisModel.sshPass, targetHost: self.redisModel.host, targetPort: self.redisModel.port)
        let localChannel = try await sshTunnel.openSSHTunnel()
        
        let localBindPort:Int = localChannel.localAddress?.port ?? 0
        self.logger.info("init forwarding server success, local port: \(localBindPort)")
        self.sshLocalChannel = localChannel
        
        return try initPool(host: bindHost, port: localBindPort, username: self.redisModel.username, pass: self.redisModel.password, database: self.redisModel.database)
    }
}
