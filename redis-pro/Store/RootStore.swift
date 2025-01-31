//
//  RootStore.swift
//  redis-pro
//
//  Created by chengpanwang on 2025/1/25.
//

import Logging
import Foundation
import ComposableArchitecture

private let logger = Logger(label: "root-store")

@Reducer
struct RootStore {
    
    @ObservableState
    struct State {
        var windows: IdentifiedArrayOf<AppStore.State> = []
        var title: String = "Redis Pro"
    }
    
    enum Action {
        case windows(IdentifiedActionOf<AppStore>)
        case addWindow(String)
        case close
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .addWindow(id):
                logger.info("add new window: \(id)")
                    
                state.windows.append(AppStore.State(id: id))
                return .none
            case .close:
                logger.info("close window")
                state.windows.removeLast()
                return .none
            case .windows(_):
                return .none
            }
        }
        .forEach(\.windows, action: \.windows) {
            AppStore()
                .dependency(\.redisClient, RediStackClient(RedisModel()))
        }

    }
}
