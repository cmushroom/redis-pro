//
//  RootStore.swift
//  redis-pro
//
//  Created by chengpanwang on 2025/1/25.
//

import Logging
import Foundation
import Dependencies
import ComposableArchitecture

private let logger = Logger(label: "root-store")

@Reducer
struct RootStore {
    
    @ObservableState
    struct State {
        var windows: IdentifiedArrayOf<AppStore.State> = []
        var title: String = "Redis Pro"
        var settings: SettingsStore.State = SettingsStore.State()
    }
    
    enum Action {
        case windows(IdentifiedActionOf<AppStore>)
        case addWindow(String)
        case close
        case none
        case settings(SettingsStore.Action)
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .addWindow(id):
                logger.info("add new window: \(id)")
                    
                let redisClient = RediStackClient(RedisModel())
                let appState = withDependencies {
                    $0.redisClient = redisClient
                } operation: {
                    // Construct the feature's model
                    AppStore.State(id: id)
                }
                state.windows.append(appState)
                return .run { send in
                    redisClient.sendAction = send
                    await send(.none)
                }
//                return .none
            case .close:
                logger.info("close window")
                state.windows.removeLast()
                return .none
            case .none:
                return .none
            case .windows(_):
                return .none
            case .settings(_):
                return .none
            }
            
        }
        .forEach(\.windows, action: \.windows) {
            AppStore()
        }

    }
}
