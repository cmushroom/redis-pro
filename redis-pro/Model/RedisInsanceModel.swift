//
//  RedisInsanceModel.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/1/25.
//

import SwiftUI
import Foundation
import NIO
import RediStack
import Logging


class RedisInstanceModel:ObservableObject, Identifiable {
    @Published var loading:Bool = false
    @Published var isConnect:Bool = false
    var redisModel:RedisModel
    private var rediStackClient:RediStackClient?
    
    let logger = Logger(label: "redis-instance")
    
    init(redisModel: RedisModel) {
        self.redisModel = redisModel
        logger.info("redis instance model init")
    }
    
    func getClient() -> RediStackClient {
        if rediStackClient != nil {
            return rediStackClient!
        }
        
        logger.info("get new redis client ...")
        rediStackClient = RediStackClient(redisModel:redisModel)
        return rediStackClient!
    }
    
    
    func queryKeyPage(page:Page, keywords:String) throws -> Void{
            let v2 = try getClient().pageKeys(page: page, keywords: keywords)
            logger.info("query key page : \(v2)")

    }
    
    func connect(redisModel:RedisModel) throws -> Void {
        self.redisModel = redisModel
        isConnect = try getClient().ping()
        if !isConnect {
            throw BizError(message: "connect redis server error")
        }
    }
    
    func testConnect() throws -> Bool {
        defer {
            close()
        }
        
        return try getClient().ping()
    }
    
    func close() -> Void {
        logger.info("redis stack client close...")
        rediStackClient?.close()
        rediStackClient = nil
        isConnect = false
    }
}
