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
    
}

private let logger = Logger(label: "redis-system-store")
struct RedisSystemState: Equatable {
    var systemView: RedisSystemViewTypeEnum = .REDIS_INFO
    var redisInfoState: RedisInfoState = RedisInfoState()
    
    init() {
        logger.info("redis system state init ...")
    }
}

enum RedisSystemAction: Equatable {
    case initial
    case setSystemView(RedisSystemViewTypeEnum)
    case redisInfoAction(RedisInfoAction)
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
        }
    }
)
