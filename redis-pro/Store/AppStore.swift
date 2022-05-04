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
    var loading: Bool = false
    var appAlertState: AppAlertState = AppAlertState()
    var loadingState: LoadingState = LoadingState()
    var favoriteState: FavoriteState = FavoriteState()
    var settingsState: SettingsState = SettingsState()
    var alert: AlertState<AppAction>?

    init() {
        logger.info("app state init ...")
    }
}

enum AppAction:Equatable {
    case onStart
    case loading(Bool)
    case alert
    case clearAlert
    case alertAction(AlertAction)
    case loadingAction(LoadingAction)
    case favoriteAction(FavoriteAction)
    case settingsAction(SettingsAction)
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
    Reducer<AppState, AppAction, AppEnvironment> {
        state, action, _ in
        switch action {
        case .onStart:
            let _ = settingsReducer.run(&state.settingsState, .initial, SettingsEnvironment())
            return .none
        case let .loading(loading):
            state.loading = loading
            return .none
        case .alert:
            state.alert = .init(
                    title: TextState("Delete"),
                    message: TextState("Are you sure you want to delete this? It cannot be undone."),
                    primaryButton: .default(TextState("Confirm"), action: .send(.onStart)),
                    secondaryButton: .cancel(TextState("Cancel"))
                  )
            return .none
        case .clearAlert:
            state.alert = nil
            return .none
        case .alertAction:
            return .none
        case .loadingAction:
            return .none
        case .favoriteAction:
            return .none
        case .settingsAction:
            return .none
        }
    }.debug()
)
