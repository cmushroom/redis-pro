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


struct SlowLogStore: Reducer {
    struct State: Equatable {
        
        @BindingState var slowerThan:Int = 10000
        @BindingState var maxLen:Int = 128
        @BindingState var size:Int = 50
        var total:Int = 0
        
        var tableState: TableStore.State = TableStore.State(columns: [
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

    enum Action:BindableAction, Equatable {
        case initial
        case getValue
        case setValue([SlowLogModel], Int, Int, Int)
        case refresh
        case reset
        case setSlowerThan
        case setMaxLen
        case setSize
        case none
        case tableAction(TableStore.Action)
        case binding(BindingAction<State>)
    }
    
    @Dependency(\.redisInstance) var redisInstanceModel:RedisInstanceModel
    let mainQueue: AnySchedulerOf<DispatchQueue> = .main
    
    var body: some Reducer<State, Action> {
        BindingReducer()
        Scope(state: \.tableState, action: /Action.tableAction) {
            TableStore()
        }
        Reduce { state, action in
            switch action {
            // 初始化已设置的值
            case .initial:
            
                logger.info("redis config store initial...")
                return .run { send in
                    await send(.getValue)
                }
                
            case .refresh:
                return .run { send in
                    await send(.getValue)
                }
                
            case .getValue:
                let size = state.size
                return .run { send in
                    let datasource = await redisInstanceModel.getClient().getSlowLog(size)
                    let total = await redisInstanceModel.getClient().slowLogLen()
                    let maxLen = await redisInstanceModel.getClient().getConfigOne(key: "slowlog-max-len")
                    let slowerThan = await redisInstanceModel.getClient().getConfigOne(key: "slowlog-log-slower-than")
                    await send(.setValue(datasource, total, NumberHelper.toInt(maxLen), NumberHelper.toInt(slowerThan)))
                }

            case let .setValue(slowLogs, total, maxLen, slowerThan):
                state.tableState.datasource = slowLogs
                state.total = total
                state.maxLen = maxLen
                state.slowerThan = slowerThan
                
                return .none
            case .reset:
                return .run { send in
                    let _ = await redisInstanceModel.getClient().slowLogReset()
                    await send(.refresh)
                }
                
            case .setSlowerThan:
                let slowerThan = state.slowerThan
                return .run { send in
                    let _ = await redisInstanceModel.getClient().setConfig(key: "slowlog-log-slower-than", value: "\(slowerThan)")
                    await send(.none)
                }
            case .setMaxLen:
                let maxLen = state.maxLen
                return .run { send in
                    let _ = await redisInstanceModel.getClient().setConfig(key: "slowlog-max-len", value: "\(maxLen)")
                }
                
            case .setSize:
                return .run { send in
                    await send(.getValue)
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
    }
}
