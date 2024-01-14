//
//  IndexView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/8.
//

import SwiftUI
import Logging
import ComposableArchitecture

struct IndexView: View {
    @State var appState:AppStore.State?
    var settingStore: StoreOf<SettingsStore>
    let logger = Logger(label: "index-view")
    
    
    init(settingStore: StoreOf<SettingsStore>) {
        logger.info("index view init ...")
        self.settingStore = settingStore
    }
    
    var body: some View {
        if let state = appState {
            let redisInstanceModel = RedisInstanceModel(RedisModel(), settingViewStore: ViewStore(settingStore, observe: { $0 }))
            let redisClient = RediStackClient(RedisModel(), settingViewStore: ViewStore(settingStore, observe: { $0 }))
            
            let store: StoreOf<AppStore> = Store(initialState: state) {
                AppStore()
                    ._printChanges()
            } withDependencies: {
                $0.redisInstance = redisInstanceModel
                $0.redisClient = redisClient
            }
            
            
            WithViewStore(store, observe: { $0.isConnect }) {viewStore in
                ZStack {
                    VStack {
                        if (viewStore.state) {
                            HomeView(store: store)
                        } else {
                            LoginView(store: store)
                        }
                        
                        
                        
                    }
                    
                    LoadingView()
                    
                }.onAppear {
                    redisInstanceModel.setAppStore(store)
                }
            }
            
        } else {
            Spacer()
                .onAppear {
                    appState = AppStore.State()
                }
        }
    }
}
