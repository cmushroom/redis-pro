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


struct RedisInfoStore: ReducerProtocol {
    struct State: Equatable {
        var section:String = "Server"
        var tableState: TableStore.State = TableStore.State(columns: [.init(title: "Key", key: "key", width: 120), .init(title: "Value", key: "value", width: 100), .init(title: "Desc", key: "desc", width: 800)]
                                                , datasource: [], selectIndex: -1)
        var redisInfoModels:[RedisInfoModel] = [RedisInfoModel(section: "Server")]
        
        init() {
            logger.info("redis info state init ...")
        }
    }

    enum Action: Equatable {
        case initial
        case getValue
        case setValue([RedisInfoModel])
        case setTab(String)
        case refresh
        case resetState
        case tableAction(TableStore.Action)
    }
    
    var redisInstanceModel:RedisInstanceModel
    let mainQueue: AnySchedulerOf<DispatchQueue> = .main
    
    
    var body: some ReducerProtocol<State, Action> {
        Scope(state: \.tableState, action: /Action.tableAction) {
            TableStore()
        }
        Reduce { state, action in
            switch action {
            // 初始化已设置的值
            case .initial:
            
                logger.info("redis info store initial...")
                return .result {
                    .success(.getValue)
                }
            
            case .getValue:
                return .task {
                    let r = await redisInstanceModel.getClient().info()
                    return .setValue(r)
                }
                .receive(on: mainQueue)
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
                    let _ = await redisInstanceModel.getClient().resetState()
                    return .refresh
                }
                .receive(on: mainQueue)
                .eraseToEffect()
                
            case .tableAction:
                return .none
            }
        }
    }

}
