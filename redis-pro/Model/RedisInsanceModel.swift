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
    @Published var redisModel:RedisModel
    private var rediStackClient:RediStackClient?
    private var viewStore:ViewStore<GlobalState, GlobalAction>?
    
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
    
//    func setGlobalStore(_ viewStore: ViewStore<GlobalState, GlobalAction>?) {
//        guard let viewStore = viewStore else {
//            return
//        }
//        self.viewStore = viewStore
//    }
    
    func setAppStore(_ appStore: Store<AppState, AppAction>) {
        let globalStore = appStore.scope(state: \.globalState, action: AppAction.globalAction)
        self.viewStore = ViewStore(globalStore)
    }
    
    // get client
    func getClient() -> RediStackClient {
        if let client = rediStackClient {
            return client
        }
        
        return initRedisClient(self.redisModel)
    }
    
    // init redis client
    func initRedisClient(_ redisModel: RedisModel) -> RediStackClient {
        
        logger.info("init new redis client, redisModel: \(redisModel)")
        self.redisModel = redisModel
        let client = RediStackClient(redisModel)
        client.setGlobalStore(self.viewStore)
        
        self.rediStackClient = client
        return client
    }
    
    func connect(_ redisModel:RedisModel) async -> Bool {
        logger.info("connect to redis server: \(redisModel)")
        
        let client = initRedisClient(redisModel)
        
        return await client.ping()
    }
    
    func testConnect(_ redisModel:RedisModel) async -> Bool {
        defer {
            self.close()
        }
        
        logger.info("test connect to redis server: \(redisModel)")
        return  await initRedisClient(redisModel).ping()
    }
    
    func close() -> Void {
        logger.info("redis stack client close...")
        rediStackClient?.close()
        rediStackClient = nil
    }
}
