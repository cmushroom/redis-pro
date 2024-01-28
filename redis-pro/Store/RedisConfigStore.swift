//
//  RedisConfigStore.swift
//  redis-pro
//
//  Created by chengpan on 2022/6/4.
//


import Logging
import Foundation
import ComposableArchitecture

private let logger = Logger(label: "redis-config-store")

struct RedisConfigStore: Reducer {
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
            
            case .getValue:
                let pattern = state.pattern
                return .run { send in
                    let r = await redisInstanceModel.getClient().getConfigList(pattern)
                    await send(.setValue(r))
                }
            
            case let .setValue(redisConfigs):
                state.tableState.datasource = redisConfigs
                
                return .none
                

            case .refresh:
                return .run { send in
                    await send(.getValue)
                }
                
            case let .search(keywords):
                state.pattern = keywords
                return .run { send in
                    await send(.getValue)
                }
            
            case .rewrite:
                return .run { send in
                    let _ = await redisInstanceModel.getClient().configRewrite()
                    await send(.refresh)
                }
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
                
                return .run { send in
                    let _ = await redisInstanceModel.getClient().setConfig(key: key, value: value)
                    await send(.refresh)
                }
                
            // table action
            case let .tableAction(.contextMenu(title, index)):
              if title == "Edit" {
                    return .run { send in
                        await send(.edit(index))
                    }
                }
                
                return .none
                
            case let .tableAction(.double(index)):
                return .run { send in
                    await send(.edit(index))
                }
            case .tableAction:
                return .none
            case .binding:
                return .none
            }
        }
    }
    
}
