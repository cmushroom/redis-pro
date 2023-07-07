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
    let logger = Logger(label: "index-view")
    
    
    init() {
        logger.info("index view init ...")
    }
    
    var body: some View {
        if let state = appState {
            let redisInstanceModel = RedisInstanceModel(redisModel: RedisModel())
//            let appContext = AppContext()
            let store: StoreOf<AppStore> = Store(initialState: state) {
                AppStore()
            } withDependencies: {
                $0.redisInstance = redisInstanceModel
//                $0.appContext = appContext
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
                    
                    LoadingView(store.scope(state: \.globalState, action: AppStore.Action.globalAction))
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
