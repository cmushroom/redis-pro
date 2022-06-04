//
//  RedisInfoStore.swift
//  redis-pro
//
//  Created by chengpan on 2022/6/4.
//

import Logging
import Foundation
import SwiftyJSON
import ComposableArchitecture

private let logger = Logger(label: "redis-info-store")
struct RedisInfoState: Equatable {
    var section:String = "# Server"
    var tableState: TableState = TableState(columns: [.init(title: "Key", key: "key", width: 120), .init(title: "Value", key: "value", width: 100), .init(title: "Desc", key: "desc", width: 800)]
                                            , datasource: [], selectIndex: -1)
    var redisInfoModels:[RedisInfoModel] = [RedisInfoModel(section: "Server")]
    
    init() {
        logger.info("redis info state init ...")
    }
}

enum RedisInfoAction: Equatable {
    case initial
    case getValue
    case setValue([RedisInfoModel])
    case setTab(String)
    case refresh
    case resetState
    case tableAction(TableAction)
}

struct RedisInfoEnvironment {
    var redisInstanceModel:RedisInstanceModel
}

let redisInfoReducer = Reducer<RedisInfoState, RedisInfoAction, SystemEnvironment<RedisInfoEnvironment>>.combine(
    tableReducer.pullback(
        state: \.tableState,
        action: /RedisInfoAction.tableAction,
        environment: { _ in .init() }
    ),
    Reducer<RedisInfoState, RedisInfoAction, SystemEnvironment<RedisInfoEnvironment>> {
        state, action, env in
        switch action {
        // 初始化已设置的值
        case .initial:
        
            logger.info("redis info store initial...")
            return .result {
                .success(.getValue)
            }
        
        case .getValue:
            return .task {
                let r = await env.redisInstanceModel.getClient().info()
                return .setValue(r)
            }
            .receive(on: env.mainQueue)
            .eraseToEffect()
        
        case let .setValue(redisInfos):
            let section = redisInfos.count > 0 ? redisInfos[0].section : ""
            state.redisInfoModels = redisInfos
            
            return .result {
                .success(.setTab(section))
            }
            
        case let .setTab(tab):
            state.section = tab
            state.tableState.selectIndex = -1
            let redisInfoModels = state.redisInfoModels
            
            guard redisInfoModels.count > 0 else {
                return .result {
                    .success(.tableAction(.reset))
                }
            }
            
            let redisInfoModel = redisInfoModels.first(where: {
                $0.section == tab
            })
            state.tableState.datasource = redisInfoModel?.infos ?? []
            
            return .none
        
        case .refresh:
            return .result {
                .success(.getValue)
            }
            
        case .resetState:
            return .task {
                let _ = await env.redisInstanceModel.getClient().resetState()
                return .refresh
            }
            .receive(on: env.mainQueue)
            .eraseToEffect()
            
        case .tableAction:
            return .none
        }
    }
).debug()
