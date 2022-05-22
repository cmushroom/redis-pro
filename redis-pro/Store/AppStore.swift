//
//  AppStore.swift
//  redis-pro
//
//  Created by chengpan on 2022/4/30.
//


import Logging
import Foundation
import ComposableArchitecture

private let logger = Logger(label: "app-store")

struct AppState: Equatable {
    // app title
    var title:String = ""
    // 是否已经连接 redis server
    var isConnect: Bool = false
    var appAlertState: AppAlertState = AppAlertState()
    var loadingState: LoadingState = LoadingState()
    var favoriteState: FavoriteState = FavoriteState()
    var settingsState: SettingsState = SettingsState()
    var redisKeysState: RedisKeysState = RedisKeysState()

    init() {
        logger.info("app state init ...")
    }
}

enum AppAction:Equatable {
    case onStart
    case onClose
    case alertAction(AlertAction)
    case loadingAction(LoadingAction)
    case favoriteAction(FavoriteAction)
    case settingsAction(SettingsAction)
    case redisKeysAction(RedisKeysAction)
}

struct AppEnvironment {
    var redisInstanceModel:RedisInstanceModel = RedisInstanceModel(redisModel: RedisModel())
}


let appReducer = Reducer<AppState, AppAction, AppEnvironment>.combine(
    favoriteReducer.pullback(
      state: \.favoriteState,
      action: /AppAction.favoriteAction,
      environment: { env in FavoriteEnvironment(redisInstanceModel: env.redisInstanceModel) }
    ),
    settingsReducer.pullback(
      state: \.settingsState,
      action: /AppAction.settingsAction,
      environment: { _ in SettingsEnvironment() }
    ),
    alertReducer.pullback(
      state: \.appAlertState,
      action: /AppAction.alertAction,
      environment: { _ in AlertEnvironment() }
    ),
    loadingReducer.pullback(
      state: \.loadingState,
      action: /AppAction.loadingAction,
      environment: { _ in LoadingEnvironment() }
    ),
    redisKeysReducer.pullback(
      state: \.redisKeysState,
      action: /AppAction.redisKeysAction,
      environment: { env in .init(redisInstanceModel: env.redisInstanceModel) }
    ),
    Reducer<AppState, AppAction, AppEnvironment> {
        state, action, env in
        switch action {
        case .onStart:
            let _ = settingsReducer.run(&state.settingsState, .initial, SettingsEnvironment())
            return .none
        
        case .onClose:
            env.redisInstanceModel.close()
            state.isConnect = false
            return .none
            
        case .alertAction:
            return .none
        case .loadingAction:
            return .none
        case let .favoriteAction(.connectSuccess(redisModel)):
            state.isConnect = true
            state.title = redisModel.name
            return .none
        case .favoriteAction:
            return .none
        case .settingsAction:
            return .none
        case .redisKeysAction:
            return .none
        }
    }.debug()
)


struct Test {
    var a:String = UUID().uuidString
    init() {
        logger.info("app state init ...")
    }
}
