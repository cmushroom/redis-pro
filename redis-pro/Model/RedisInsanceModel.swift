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
import ComposableArchitecture

class RedisInstanceModel:ObservableObject, Identifiable {
    @Published var loading:Bool = false
    @Published var isConnect:Bool = false
    @Published var redisModel:RedisModel
    private var rediStackClient:RediStackClient?
    var globalContext:GlobalContext?
    
    // 页面处理 loading , alert 等
    private var loadingStore: Store<LoadingState, LoadingAction>?
    private var loadingViewStore: ViewStore<LoadingState, LoadingAction>?
    private var alertStore: Store<AppAlertState, AlertAction>?
    private var alertViewStore: ViewStore<AppAlertState, AlertAction>?
    
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
    
    func setUp(_ loadingStore:Store<LoadingState, LoadingAction>, alertStore: Store<AppAlertState, AlertAction>) -> Void {
        self.loadingStore = loadingStore
        self.loadingViewStore = ViewStore(loadingStore)
        self.alertStore = alertStore
        self.alertViewStore = ViewStore(alertStore)
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
        rediStackClient?.setUp(self.globalContext)
        return rediStackClient!
    }
    
    func connect(redisModel:RedisModel) async -> Bool {
        logger.info("connect to redis server: \(redisModel)")
        self.redisModel = redisModel
        let r = await self.getClient().initConnection()
        DispatchQueue.main.async {
            self.isConnect = r
        }
        return r
    }
    
    func testConnect(_ redisModel:RedisModel) async -> Bool {
        self.redisModel = redisModel
        let pong =  await self.getClient().ping()
        self.close()
        return pong
    }
    
    func close() -> Void {
        logger.info("redis stack client close...")
        rediStackClient?.close()
        rediStackClient = nil
        isConnect = false
    }
}
