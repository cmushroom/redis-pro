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

class RedisInstanceModel: Identifiable {
    var redisModel:RedisModel
    private var rediStackClient:RediStackClient?
    private var appContextviewStore:ViewStoreOf<AppContextStore>?
    private var settingViewStore:ViewStoreOf<SettingsStore>?
    
    let logger = Logger(label: "redis-instance")
    
    
    init(redisModel: RedisModel) {
        self.redisModel = redisModel
        logger.info("redis instance model init")
    }
    
    convenience init(_ redisModel:RedisModel, settingViewStore: ViewStoreOf<SettingsStore>?) {
        self.init(redisModel: redisModel)
        self.settingViewStore = settingViewStore
    }
    
    convenience init(_ redisClient: RediStackClient, settingViewStore: ViewStoreOf<SettingsStore>?) {
        self.init(redisModel: redisClient.redisModel)
        self.rediStackClient = redisClient
        self.settingViewStore = settingViewStore
    }
    
    
    func setAppStore(_ appStore: StoreOf<AppStore>) {
        let globalStore = appStore.scope(state: \.globalState, action: AppStore.Action.globalAction)
        self.appContextviewStore = ViewStore(globalStore, observe: { $0 })
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
        let client = RediStackClient(redisModel, settingViewStore: settingViewStore)
        client.setAppContextStore(self.appContextviewStore)
        
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
