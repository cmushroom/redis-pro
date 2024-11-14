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
    let logger = Logger(label: "index-view")
//    @State var appState:AppStore.State?
    var settingStore: StoreOf<SettingsStore>
    let store:StoreOf<AppStore>
    

//    init(settingStore: StoreOf<SettingsStore>) {
//        logger.info("index view init ...")
//        self.settingStore = settingStore
//    }
    
    var body: some View {
        
        WithPerceptionTracking {
            ZStack {
                VStack {
                    Text("\(store.isConnect)")
                    //                if (store.isConnect) {
                    //                    Text("hello")
                    ////                    HomeView(store: store)
                    //                } else {
                    ////                    LoginView(store: store)
                    //                }
                }
                
                //            LoadingView()
            }
        }
        
//        if let state = appState {
//            let redisInstanceModel = RedisInstanceModel(redisModel: RedisModel())
//            let redisClient = RediStackClient(RedisModel())
//            
//            let store: StoreOf<AppStore> = Store(initialState: state) {
//                AppStore()
//                    ._printChanges()
//            } withDependencies: {
//                $0.redisInstance = redisInstanceModel
//                $0.redisClient = redisClient
//            }
//            
//            
////            WithViewStore(store, observe: { $0.isConnect }) {viewStore in
//                ZStack {
//                    VStack {
//                        Text("\(store.isConnect)")
//                        if (store.isConnect) {
//                            HomeView(store: store)
//                        } else {
//                            LoginView(store: store)
//                        }
//                    }
//                    
//                    LoadingView()
//                }
////            }
//            
//        } else {
//            Spacer()
//                .onAppear {
//                    appState = AppStore.State()
//                }
//        }
    }
}
