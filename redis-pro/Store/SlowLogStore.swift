//
//  SlowLogStore.swift
//  redis-pro
//
//  Created by chengpan on 2022/6/4.
//


import Logging
import Foundation
import SwiftyJSON
import ComposableArchitecture

private let logger = Logger(label: "redis-config-store")
struct SlowLogState: Equatable {
    
    @BindableState var slowerThan:Int = 10000
    @BindableState var maxLen:Int = 128
    @BindableState var size:Int = 50
    var total:Int = 0
    
    var tableState: TableState = TableState(columns: [
        .init(title: "Id", key: "id", width: 60),
        .init(title: "Timestamp", key: "timestamp", width: 120),
        .init(title: "Exec Time(us)", key: "execTime", width: 90),
        .init(title: "Client", key: "client", width: 140),
        .init(title: "Client Name", key: "clientName", width: 100),
        .init(title: "Cmd", key: "cmd", width: 100),
    ], datasource: [], selectIndex: -1)
    
    init() {
        logger.info("slow log state init ...")
    }
}

enum SlowLogAction:BindableAction, Equatable {
    case initial
    case getValue
    case setValue([SlowLogModel], Int, Int, Int)
    case refresh
    case reset
    case setSlowerThan
    case setMaxLen
    case setSize
    case none
    case tableAction(TableAction)
    case binding(BindingAction<SlowLogState>)
}

struct SlowLogEnvironment {
    var redisInstanceModel:RedisInstanceModel
}

let slowLogReducer = Reducer<SlowLogState, SlowLogAction, SystemEnvironment<SlowLogEnvironment>>.combine(
    tableReducer.pullback(
        state: \.tableState,
        action: /SlowLogAction.tableAction,
        environment: { _ in .init() }
    ),
    Reducer<SlowLogState, SlowLogAction, SystemEnvironment<SlowLogEnvironment>> {
        state, action, env in
        switch action {
        // 初始化已设置的值
        case .initial:
        
            logger.info("redis config store initial...")
            return .result {
                .success(.getValue)
            }
            
        case .refresh:
            return .result {
                .success(.getValue)
            }
            
        case .getValue:
            let size = state.size
            return .task {
                let datasource = await env.redisInstanceModel.getClient().getSlowLog(size)
                let total = await env.redisInstanceModel.getClient().slowLogLen()
                let maxLen = await env.redisInstanceModel.getClient().getConfigOne(key: "slowlog-max-len")
                let slowerThan = await env.redisInstanceModel.getClient().getConfigOne(key: "slowlog-log-slower-than")
                return .setValue(datasource, total, NumberHelper.toInt(maxLen), NumberHelper.toInt(slowerThan))
            }
            .receive(on: env.mainQueue)
            .eraseToEffect()

        case let .setValue(slowLogs, total, maxLen, slowerThan):
            state.tableState.datasource = slowLogs
            state.total = total
            state.maxLen = maxLen
            state.slowerThan = slowerThan
            
            return .none
        case .reset:
            return .task {
                let _ = await env.redisInstanceModel.getClient().slowLogReset()
                return .refresh
            }
            .receive(on: env.mainQueue)
            .eraseToEffect()
            
        case .setSlowerThan:
            let slowerThan = state.slowerThan
            return .task {
                let _ = await env.redisInstanceModel.getClient().setConfig(key: "slowlog-log-slower-than", value: "\(slowerThan)")
                return .none
            }
            .receive(on: env.mainQueue)
            .eraseToEffect()
        case .setMaxLen:
            let maxLen = state.maxLen
            return .task {
                let _ = await env.redisInstanceModel.getClient().setConfig(key: "slowlog-max-len", value: "\(maxLen)")
                return .none
            }
            .receive(on: env.mainQueue)
            .eraseToEffect()
            
        case .setSize:
            return .result {
                .success(.getValue)
            }
            
            
        // table action
        case .tableAction:
            return .none
        case .binding:
            return .none
        case .none:
            return .none
        }
    }
).binding().debug()
