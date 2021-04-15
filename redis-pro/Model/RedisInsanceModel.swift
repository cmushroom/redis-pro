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
    @Published var alertContext:AlertContext = AlertContext()
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
        
        rediStackClient = RediStackClient(redisModel:redisModel)
        return rediStackClient!
    }
    
    
    func queryKeyPage(page:Page, keywords:String) -> Void{
        do {
            let v2 = try getClient().pageKeys(page: page, keywords: keywords)
            logger.info("query key page : \(v2)")
        } catch {
            logger.error("query key page error \(error)")
            alertContext = AlertContext(true, msg: "query key page error \(error)")
        }
    }
    
    func connect(redisModel:RedisModel) throws -> Void {
        self.redisModel = redisModel
        try getClient().ping()
        isConnect = true
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
    }
}
