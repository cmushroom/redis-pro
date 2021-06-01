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
import PromiseKit


class RedisInstanceModel:ObservableObject, Identifiable {
    @Published var loading:Bool = false
    @Published var isConnect:Bool = false
    @Published var redisModel:RedisModel
    private var rediStackClient:RediStackClient?
    var globalContext:GlobalContext?
    
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
    
    func setUp(_ globalContext:GlobalContext) -> Void {
        self.globalContext = globalContext
    }
    
    func getClient() -> RediStackClient {
        if rediStackClient != nil {
            return rediStackClient!
        }
        
        logger.info("get new redis client ...")
        rediStackClient = RediStackClient(redisModel:redisModel)
        rediStackClient?.setUp(self.globalContext!)
        return rediStackClient!
    }
    
    func connect(redisModel:RedisModel) throws -> Void {
        logger.info("connect to redis server: \(redisModel)")
        
        self.globalContext?.loading = true
        
        self.redisModel = redisModel
        getClient().initConnection().done({ r in
            self.globalContext?.loading = false
            self.isConnect = r
        })
        .catch({ error in
            self.globalContext?.loading = false
            self.globalContext?.showError(error)
            self.close()
        })
        
    }
    
    func testConnect(redisModel:RedisModel) throws -> Bool {
        self.redisModel = redisModel
        
        defer {
            close()
        }
        
        return try getClient().ping()
    }
    
    func testConnectAsync(_ redisModel:RedisModel) -> Promise<Bool> {
        self.redisModel = redisModel
        
        let promise = getClient().initConnection().then({ _ in
            self.getClient().pingAsync()
        })
        
        promise
            .catch({error in
                self.globalContext?.showError(error)
            })
            .finally {
                self.close()
            }
        return promise
    }
    
    func close() -> Void {
        logger.info("redis stack client close...")
        rediStackClient?.close()
        rediStackClient = nil
        isConnect = false
    }
}
