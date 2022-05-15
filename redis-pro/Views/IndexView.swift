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

    var store:Store<AppState, AppAction>
    
    
    private let logger = Logger(label: "index-view")
    
    
    init() {
        logger.info("index view init ...")
        let env = AppEnvironment()
        store = Store(initialState: AppState(), reducer: appReducer, environment: env)
    }
    
    var body: some View {
        WithViewStore(store) { viewStore in
            ZStack {
                VStack {
                    if (viewStore.isConnect) {
                        HomeView(store)
                            .environmentObject(redisInstanceModel)
                        // 设置window标题
                            .navigationTitle(viewStore.title)
                    } else {
                        LoginView(store: store)
                            .environmentObject(redisInstanceModel)
                    }
                }
                
                AlertView(store.scope(state: \.appAlertState, action: AppAction.alertAction))
                LoadingView(store.scope(state: \.loadingState, action: AppAction.loadingAction))
            }
            .environmentObject(globalContext)
            .onAppear {
            }
            //        .overlay(MSpin(loading: globalContext.loading))
            .alert(isPresented: $globalContext.alertVisible) {
                globalContext.showSecondButton ? Alert(title: Text(globalContext.alertTitle), message: Text(globalContext.alertMessage),
                                                       primaryButton: .default(Text(globalContext.primaryButtonText),
                                                                               action: doAction),
                                                       secondaryButton: .cancel(Text(globalContext.secondButtonText), action: cancelAction)) : Alert(title: Text(globalContext.alertTitle), message: Text(globalContext.alertMessage), dismissButton: .default(Text(globalContext.primaryButtonText)))
            }
        }
    }
    
    
    func doAction() -> Void {
        logger.info("alert ok action ...")
        do {
            try globalContext.primaryAction()
        } catch {
            globalContext.showError(error)
        }
        
    }
    func cancelAction() -> Void {
        logger.info("alert cancel action ...")
        logger.info("redis instance : \(redisInstanceModel.redisModel)")
    }
}

//struct IndexView_Previews: PreviewProvider {
//    static var previews: some View {
//        IndexView()
//    }
//}
