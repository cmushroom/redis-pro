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
    case REDIS_INFO
    case REDIS_CONFIG
    case CLIENT_LIST
    case SLOW_LOG
    case LUA
    
}

private let logger = Logger(label: "redis-system-store")
struct RedisSystemState: Equatable {
    var systemView: RedisSystemViewTypeEnum = .REDIS_INFO
    var redisInfoState: RedisInfoState = RedisInfoState()
    var redisConfigState: RedisConfigState = RedisConfigState()
    var slowLogState: SlowLogState = SlowLogState()
    var clientListState: ClientListState = ClientListState()
    var luaState: LuaState = LuaState()
    
    init() {
        logger.info("redis system state init ...")
    }
}

enum RedisSystemAction: Equatable {
    case initial
    case setSystemView(RedisSystemViewTypeEnum)
    case redisInfoAction(RedisInfoAction)
    case redisConfigAction(RedisConfigAction)
    case slowLogAction(SlowLogAction)
    case clientListAction(ClientListAction)
    case luaAction(LuaAction)
}

struct RedisSystemEnvironment {
    var redisInstanceModel:RedisInstanceModel
}

let redisSystemReducer = Reducer<RedisSystemState, RedisSystemAction, SystemEnvironment<RedisSystemEnvironment>>.combine(
    redisInfoReducer.pullback(
        state: \.redisInfoState,
        action: /RedisSystemAction.redisInfoAction,
        environment: { env in  .live(environment: RedisInfoEnvironment(redisInstanceModel: env.redisInstanceModel)) }
    ),
    redisConfigReducer.pullback(
        state: \.redisConfigState,
        action: /RedisSystemAction.redisConfigAction,
        environment: { env in  .live(environment: RedisConfigEnvironment(redisInstanceModel: env.redisInstanceModel)) }
    ),
    slowLogReducer.pullback(
        state: \.slowLogState,
        action: /RedisSystemAction.slowLogAction,
        environment: { env in  .live(environment: SlowLogEnvironment(redisInstanceModel: env.redisInstanceModel)) }
    ),
    clientListReducer.pullback(
        state: \.clientListState,
        action: /RedisSystemAction.clientListAction,
        environment: { env in  .live(environment: ClientListEnvironment(redisInstanceModel: env.redisInstanceModel)) }
    ),
    luaReducer.pullback(
        state: \.luaState,
        action: /RedisSystemAction.luaAction,
        environment: { env in  .live(environment: LuaEnvironment(redisInstanceModel: env.redisInstanceModel)) }
    ),
    Reducer<RedisSystemState, RedisSystemAction, SystemEnvironment<RedisSystemEnvironment>> {
        state, action, env in
        switch action {
        // 初始化已设置的值
        case .initial:
            return .none
        case let .setSystemView(type):
            state.systemView = type
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
)
