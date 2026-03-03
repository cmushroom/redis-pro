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

@Reducer
struct AppStore {
    
    @ObservableState
    struct State: Equatable, Identifiable {
        var id:String = UUID().uuidString
        // app title
        var title:String = ""
        // 是否已经连接 redis server
        var isConnect: Bool = false
        @Shared(.inMemory("appContext")) var appContext = AppContextStore.State()
        var globalState = AppContextStore.State()
        var loadingState = LoadingStore.State()
        var favoriteState = FavoriteStore.State()
        var settingsState = SettingsStore.State()
        var redisKeysState = RedisKeysStore.State()
    }

    enum Action:Equatable {
        case initial
        case onStart
        case onClose
        case onConnect
        case onDisconnect
        case globalAction(AppContextStore.Action)
        case appContextAction(AppContextStore.Action)
        case loadingAction(LoadingStore.Action)
        case favoriteAction(FavoriteStore.Action)
        case settingsAction(SettingsStore.Action)
        case redisKeysAction(RedisKeysStore.Action)
    }
    
    @Dependency(\.redisClient) var redisClient: RediStackClient
    
    var body: some Reducer<State, Action> {
        
        Scope(state: \.globalState, action: \.globalAction) {
            AppContextStore()
        }
        Scope(state: \.appContext, action: \.appContextAction) {
            AppContextStore()
        }
        Scope(state: \.loadingState, action: \.loadingAction) {
            LoadingStore()
        }
        Scope(state: \.settingsState, action: \.settingsAction) {
            SettingsStore()
        }
        Scope(state: \.favoriteState, action: \.favoriteAction) {
            FavoriteStore()
        }
        Scope(state: \.redisKeysState, action: \.redisKeysAction) {
            RedisKeysStore()
        }
        
        Reduce { state, action in
            switch action {
            case .initial:
                logger.info("init app context complete...")
                return .send(.redisKeysAction(.initial))
            case .onStart:
                logger.info("app store on start...")
                return .none
            case .onClose:
                logger.info("app store on close...")
                redisClient.close()
                state.isConnect = false
                return .none
            case .onConnect:
                logger.info("app store on connect...")
                state.isConnect = true
                return .none
            case .onDisconnect:
                logger.info("app store on disconnect...")
                state.isConnect = false
                return .none
            case .globalAction:
                return .none
            case .loadingAction:
                return .none
            case let .favoriteAction(.connectSuccess(redisModel)):
                state.title = redisModel.name
                return .run {send in
                    await send(.onConnect)
                }
            case .favoriteAction:
                return .none
            case .settingsAction:
                return .none
            case .redisKeysAction:
                return .none
            case .appContextAction:
                return .none
            }
        }
    }
}
