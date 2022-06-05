//
//  RedisConfigStore.swift
//  redis-pro
//
//  Created by chengpan on 2022/6/4.
//


import Logging
import Foundation
import SwiftyJSON
import ComposableArchitecture

private let logger = Logger(label: "redis-config-store")
struct RedisConfigState: Equatable {
    
    @BindableState var editModalVisible:Bool = false
    @BindableState var editValue:String = ""
    var pattern:String = ""
    var editKey:String = ""
    var editIndex = 0
    
    var tableState: TableState = TableState(columns: [.init(title: "Key", key: "key", width: 200), .init(title: "Value", key: "value", width: 800)]
                                            , datasource: [], contextMenus: ["Edit"], selectIndex: -1)
    
    init() {
        logger.info("redis config state init ...")
    }
}

enum RedisConfigAction:BindableAction, Equatable {
    case initial
    case getValue
    case setValue([RedisConfigItemModel])
    case refresh
    case search(String)
    case rewrite
    case edit(Int)
    case submit
    case tableAction(TableAction)
    case binding(BindingAction<RedisConfigState>)
}

struct RedisConfigEnvironment {
    var redisInstanceModel:RedisInstanceModel
}

let redisConfigReducer = Reducer<RedisConfigState, RedisConfigAction, SystemEnvironment<RedisConfigEnvironment>>.combine(
    tableReducer.pullback(
        state: \.tableState,
        action: /RedisConfigAction.tableAction,
        environment: { _ in .init() }
    ),
    Reducer<RedisConfigState, RedisConfigAction, SystemEnvironment<RedisConfigEnvironment>> {
        state, action, env in
        switch action {
        // 初始化已设置的值
        case .initial:
        
            logger.info("redis config store initial...")
            return .result {
                .success(.getValue)
            }
        
        case .getValue:
            let pattern = state.pattern
            return .task {
                let r = await env.redisInstanceModel.getClient().getConfigList(pattern)
                return .setValue(r)
            }
            .receive(on: env.mainQueue)
            .eraseToEffect()
        
        case let .setValue(redisConfigs):
            state.tableState.datasource = redisConfigs
            
            return .none
            

        case .refresh:
            return .result {
                .success(.getValue)
            }
            
        case let .search(keywords):
            state.pattern = keywords
            return .result {
                .success(.getValue)
            }
        
        case .rewrite:
            return .task {
                let _ = await env.redisInstanceModel.getClient().configRewrite()
                return .refresh
            }
            .receive(on: env.mainQueue)
            .eraseToEffect()
        case let .edit(index):
            
            state.editIndex = index
            guard let item:RedisConfigItemModel = state.tableState.datasource[index] as? RedisConfigItemModel else {
                return .none
            }
            state.editKey = item.key
            state.editValue = item.value
            state.editModalVisible = true
            
            return .none
            
        case .submit:
            let key = state.editKey
            let value = state.editValue
            
            return .task {
                let _ = await env.redisInstanceModel.getClient().setConfig(key: key, value: value)
                return .refresh
            }
            .receive(on: env.mainQueue)
            .eraseToEffect()
            
        // table action
        case let .tableAction(.contextMenu(title, index)):
          if title == "Edit" {
                return .result {
                    .success(.edit(index))
                }
            }
            
            return .none
            
        case let .tableAction(.double(index)):
            return .result {
                .success(.edit(index))
            }
        case .tableAction:
            return .none
        case .binding:
            return .none
        }
    }
).binding().debug()
