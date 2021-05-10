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
    @Published var redisModel:RedisModel {
        didSet {
            print("redis model did set")
        }
    }
    private var rediStackClient:RediStackClient?
    
    let logger = Logger(label: "redis-instance")
    
    private var observers = [NSObjectProtocol]()
    
    init(redisModel: RedisModel) {
        self.redisModel = redisModel
        logger.info("redis instance model init")
        
        observers.append(
            NotificationCenter.default.addObserver(forName: NSApplication.willTerminateNotification, object: nil, queue: .main) { [self] _ in
                logger.info("redis pro will exit...")
                close()
            }
        )
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
        logger.info("connect to redis server: \(redisModel)")
        do {
            self.redisModel = redisModel
            isConnect = try getClient().ping()
            if !isConnect {
                throw BizError(message: "connect redis server error")
            }
        } catch {
            close()
            throw error
        }
    }
    
    func testConnect(redisModel:RedisModel) throws -> Bool {
        self.redisModel = redisModel
        
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
