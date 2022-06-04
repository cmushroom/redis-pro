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
    @StateObject var globalContext:GlobalContext = GlobalContext()
    @StateObject var redisInstanceModel:RedisInstanceModel = RedisInstanceModel(redisModel: RedisModel())
    
    @State var appState:AppState?
    //    var store:Store<AppState, AppAction> = Store(initialState: AppState(), reducer: appReducer, environment: AppEnvironment())
    //    private var store:Store<AppState, AppAction> = Store(initialState: AppState(), reducer: appReducer, environment: AppEnvironment())
    //    @StateObject var viewStore:ViewStore<AppState, AppAction>?
    
    private let logger = Logger(label: "index-view")
    
    
    init() {
        logger.info("index view init ...")
        //        let env = AppEnvironment()
        //        self.store = Store(initialState: AppState(), reducer: appReducer, environment: env)
        //        self.viewStore = ViewStore(store)
    }
    
    var body: some View {
        if let state = appState {
            let store: Store<AppState, AppAction> = Store(
                initialState: state,
                reducer: appReducer,
                environment:  AppEnvironment()
            )
            
            WithViewStore(store.scope(state: \.isConnect)) { viewStore in
                ZStack {
                    VStack {
                        if (viewStore.state) {
                            HomeView(store)
                                .environmentObject(redisInstanceModel)
                            // 设置window标题
                            //                            .navigationTitle(viewStore.title)
                        } else {
                            LoginView(store: store)
                                .environmentObject(redisInstanceModel)
                            Button("loading", action: {
                                viewStore.send(.globalAction(.show))
                                LoadingUtil.show()
                            })
                        }
                        
                        WithViewStore(store.scope(state: \.globalState)) { v in
                            Text("\(v.loading ? 1 : 0)")
                        }
                    }
                    
//                    AlertView(store.scope(state: \.appAlertState, action: AppAction.alertAction))
                    LoadingView(store.scope(state: \.loadingState, action: AppAction.loadingAction))
                }
                .environmentObject(globalContext)
            }
            
        } else {
            Spacer()
                .onAppear {
                    appState = AppState()
                }
        }
    }
}

//struct IndexView_Previews: PreviewProvider {
//    static var previews: some View {
//        IndexView()
//    }
//}
