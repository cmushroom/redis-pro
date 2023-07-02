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

struct RedisConfigStore: ReducerProtocol {
    struct State: Equatable {
        
        @BindingState var editModalVisible:Bool = false
        @BindingState var editValue:String = ""
        var pattern:String = ""
        var editKey:String = ""
        var editIndex = 0
        
        var tableState: TableStore.State = TableStore.State(
            columns: [.init(title: "Key", key: "key", width: 200), .init(title: "Value", key: "value", width: 800)]
            , datasource: []
            , contextMenus: [.EDIT]
            , selectIndex: -1)
        
        init() {
            logger.info("redis config state init ...")
        }
    }

    enum Action:BindableAction, Equatable {
        case initial
        case getValue
        case setValue([RedisConfigItemModel])
        case refresh
        case search(String)
        case rewrite
        case edit(Int)
        case submit
        case tableAction(TableStore.Action)
        case binding(BindingAction<State>)
    }
    
    var redisInstanceModel:RedisInstanceModel
    let mainQueue: AnySchedulerOf<DispatchQueue> = .main
    
    var body: some ReducerProtocol<State, Action> {
        BindingReducer()
        Scope(state: \.tableState, action: /Action.tableAction) {
            TableStore()
        }
        Reduce { state, action in
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
                    let r = await redisInstanceModel.getClient().getConfigList(pattern)
                    return .setValue(r)
                }
                .receive(on: mainQueue)
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
                    let _ = await redisInstanceModel.getClient().configRewrite()
                    return .refresh
                }
                .receive(on: mainQueue)
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
                    let _ = await redisInstanceModel.getClient().setConfig(key: key, value: value)
                    return .refresh
                }
                .receive(on: mainQueue)
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
    }
    
}
