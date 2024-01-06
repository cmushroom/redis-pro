//
//  RedisSystemStore.swift
//  redis-pro
//
//  Created by chengpan on 2022/6/4.
//


import Logging
import Foundation
import SwiftyJSON
import ComposableArchitecture

enum RedisSystemViewTypeEnum{
    case KEYS_DEL
    case REDIS_INFO
    case REDIS_CONFIG
    case CLIENT_LIST
    case SLOW_LOG
    case LUA
    
}

private let logger = Logger(label: "redis-system-store")

struct RedisSystemStore: Reducer {
    
    struct State: Equatable {
        var systemView: RedisSystemViewTypeEnum = .REDIS_INFO
        var keysDelState:KeysDelStore.State = KeysDelStore.State()
        var redisInfoState: RedisInfoStore.State = RedisInfoStore.State()
        var redisConfigState: RedisConfigStore.State = RedisConfigStore.State()
        var slowLogState: SlowLogStore.State = SlowLogStore.State()
        var clientListState: ClientListStore.State = ClientListStore.State()
        var luaState: LuaStore.State = LuaStore.State()
        
        init() {
            logger.info("redis system state init ...")
        }
    }

    enum Action: Equatable {
        case initial
        case setSystemView(RedisSystemViewTypeEnum)
        case keysDelAction(KeysDelStore.Action)
        case redisInfoAction(RedisInfoStore.Action)
        case redisConfigAction(RedisConfigStore.Action)
        case slowLogAction(SlowLogStore.Action)
        case clientListAction(ClientListStore.Action)
        case luaAction(LuaStore.Action)
    }
    
    @Dependency(\.redisInstance) var redisInstanceModel:RedisInstanceModel
    
    var body: some Reducer<State, Action> {
        Scope(state: \.keysDelState, action: /Action.keysDelAction) {
            KeysDelStore()
        }
        Scope(state: \.redisInfoState, action: /Action.redisInfoAction) {
            RedisInfoStore()
        }
        Scope(state: \.redisConfigState, action: /Action.redisConfigAction) {
            RedisConfigStore()
        }
        Scope(state: \.slowLogState, action: /Action.slowLogAction) {
            SlowLogStore()
        }
        Scope(state: \.clientListState, action: /Action.clientListAction) {
            ClientListStore()
        }
        Scope(state: \.luaState, action: /Action.luaAction) {
            LuaStore()
        }
        Reduce { state, action in
            switch action {
            // 初始化已设置的值
            case .initial:
                return .none
            case let .setSystemView(type):
                state.systemView = type
                return .none
                
            case .keysDelAction:
                return .none
            case .redisInfoAction:
                return .none
            case .redisConfigAction:
                return .none
            case .slowLogAction:
                return .none
            case .clientListAction:
                return .none
            case .luaAction:
                return .none
            }
        }
    }
}
