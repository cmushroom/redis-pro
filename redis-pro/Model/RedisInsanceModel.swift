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
    private var viewStore:ViewStore<GlobalStore.State, GlobalStore.Action>?
    
    let logger = Logger(label: "redis-instance")
    
    private var observers = [NSObjectProtocol]()
    
    init(redisModel: RedisModel) {
        self.redisModel = redisModel
        logger.info("redis instance model init")
        
        observers.append(
            NotificationCenter.default.addObserver(forName: NSApplication.willTerminateNotification, object: nil, queue: .main) { [self] _ in
                logger.info("redis pro will exit...")
                close()
                
                shutdown()
            }
        )
    }
    
    func setAppStore(_ appStore: StoreOf<AppStore>) {
        let globalStore = appStore.scope(state: \.globalState, action: AppStore.Action.globalAction)
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
        do {
            let r = await testConnect(redisModel)
            if r {
                let _ = try await initRedisClient(redisModel).getConn()
            }
            
            return r
        } catch {
            Messages.show(error)
            return false
        }
    }
    
    func testConnect(_ redisModel:RedisModel) async -> Bool {
        defer {
            self.close()
        }
        
        logger.info("test connect to redis server: \(redisModel)")
        return  await initRedisClient(redisModel).testConn()
    }
    
    func close() -> Void {
        logger.info("redis stack client close...")
        rediStackClient?.close()
        rediStackClient = nil
    }
    
    func shutdown() -> Void {
        rediStackClient?.shutdown()
    }
}
