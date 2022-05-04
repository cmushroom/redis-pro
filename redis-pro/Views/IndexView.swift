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
    
    @AppStorage("User.colorSchemeValue")
    private var colorSchemeValue:String = ColorSchemeEnum.SYSTEM.rawValue
    @Environment(\.colorScheme) var colorScheme
    
    @StateObject var globalContext:GlobalContext = GlobalContext()
    @StateObject var redisInstanceModel:RedisInstanceModel = RedisInstanceModel(redisModel: RedisModel())
    // @tips store 不能这样在view中初始化， view在多次渲染时， 重复初始化
    // var store:Store<AppState, AppAction> = Store(initialState: AppState(), reducer: appReducer, environment: AppEnvironment())
    var store:Store<AppState, AppAction>
//    var store:Store<AppState, AppAction> = Store(initialState: AppState(), reducer: appReducer, environment: AppEnvironment())
    
    
    private let logger = Logger(label: "index-view")
    
    var appColorScheme:ColorScheme? {
        if colorSchemeValue == ColorSchemeEnum.LIGHT.rawValue {
            return .light
        } else if colorSchemeValue == ColorSchemeEnum.DARK.rawValue {
            return .dark
        }
        
        return .none
    }
    
    init() {
        logger.info("index view init ...")
        let env = AppEnvironment()
        store = Store(initialState: AppState(), reducer: appReducer, environment: env)
        env.redisInstanceModel.setUp(store.scope(state: \.loadingState, action: AppAction.loadingAction), alertStore: store.scope(state: \.appAlertState, action: AppAction.alertAction))
    }
    
    var body: some View {
        WithViewStore(store) { viewStore in
        HStack {
            VStack {
                if (!redisInstanceModel.isConnect) {
//                    LoginView(store: Store(initialState: AppState(), reducer: appReducer, environment: AppEnvironment()))
                    LoginView(store: store)
                        .environmentObject(redisInstanceModel)
                    
                } else {
                    HomeView()
                        .environmentObject(redisInstanceModel)
                        // 设置window标题
                        .navigationTitle(redisInstanceModel.redisModel.name)
                }
                
                Button("test alert", action: {
                    viewStore.send(.alertAction(.alert))
                })
                Button("test alert", action: {
                    viewStore.send(.loadingAction(.show))
                })
                NAlert(store: store.scope(state: \.appAlertState, action: AppAction.alertAction))
                NLoading(store: store.scope(state: \.loadingState, action: AppAction.loadingAction))
            }
        }
        .preferredColorScheme(appColorScheme)
        .environmentObject(globalContext)
        .onAppear {
            redisInstanceModel.setUp(globalContext)
        }
        .overlay(MSpin(loading: globalContext.loading))
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
