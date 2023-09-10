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


struct AppStore: Reducer {
    
    struct State: Equatable {
        var id:String = UUID().uuidString
        // app title
        var title:String = ""
        // 是否已经连接 redis server
        var isConnect: Bool = false
        var globalState: AppContextStore.State = AppContextStore.State()
        var loadingState: LoadingStore.State = LoadingStore.State()
        private var _favoriteState: FavoriteStore.State = FavoriteStore.State()
        var favoriteState: FavoriteStore.State {
            get {
                var state = _favoriteState
                state.globalState = globalState
                return state
            }
            set {
                _favoriteState = newValue
                globalState = newValue.globalState!
            }
        }
        var settingsState: SettingsStore.State = SettingsStore.State()
        var redisKeysState: RedisKeysStore.State = RedisKeysStore.State()

        init() {
            logger.info("app state init ...")
            
        }
    }

    enum Action:Equatable {
        case initial
        case onStart
        case onClose
        case globalAction(AppContextStore.Action)
        case loadingAction(LoadingStore.Action)
        case favoriteAction(FavoriteStore.Action)
        case settingsAction(SettingsStore.Action)
        case redisKeysAction(RedisKeysStore.Action)
    }

    @Dependency(\.redisInstance) var redisInstanceModel: RedisInstanceModel
    var mainQueue: AnySchedulerOf<DispatchQueue> = .main
    
    
    var body: some Reducer<State, Action> {
        
        Scope(state: \.globalState, action: /Action.globalAction) {
            AppContextStore()
        }
        Scope(state: \.loadingState, action: /Action.loadingAction) {
            LoadingStore()
        }
        Scope(state: \.settingsState, action: /Action.settingsAction) {
            SettingsStore()
        }
        Scope(state: \.favoriteState, action: /Action.favoriteAction) {
            FavoriteStore()
        }
        Scope(state: \.redisKeysState, action: /Action.redisKeysAction) {
            RedisKeysStore()
        }
        
        Reduce { state, action in
            switch action {
            case .initial:
                logger.info("init app context complete...")
                return .send(.redisKeysAction(.initial))
            case .onStart:
                return .none
            
            case .onClose:
                redisInstanceModel.close()
                state.isConnect = false
                return .none
            case .globalAction:
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
        }
    }
}
