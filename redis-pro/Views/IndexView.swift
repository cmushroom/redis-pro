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
//    var store: StoreOf<AppStore> = Store(initialState: AppStore.State()) {
//        AppStore(redisInstanceModel: RedisInstanceModel(redisModel: RedisModel()))
//    }
    
    let logger = Logger(label: "index-view")
    
    
    init() {
        logger.info("index view init ...")
    }
    
    var body: some View {
//        Text("Hamlet")
//            .onAppear {
//                logger.info("index view appear ...")
//            }
//            .onDisappear {
//                logger.info("index view appear ...")
//            }
        if let state = appState {
            
            var redisInstanceModel = RedisInstanceModel(redisModel: RedisModel())
            let store: StoreOf<AppStore> = Store(initialState: state) {
                AppStore(redisInstanceModel: redisInstanceModel)
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
//                    viewStore.send(.initContext)
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

//struct IndexView_Previews: PreviewProvider {
//    static var previews: some View {
//        IndexView()
//    }
//}
