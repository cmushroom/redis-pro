//
//  KeysDeleteStore.swift
//  redis-pro
//
//  Created by chengpan on 2023/7/30.
//

import Foundation
import Logging
import ComposableArchitecture

private let logger = Logger(label: "keys-del-store")


struct KeysDelStore: Reducer {
    struct State: Equatable {
        var tableState: TableStore.State = TableStore.State(columns: [.init(title: "Type", key: "type", width: 120), .init(title: "Key", key: "key", width: 100), .init(title: "Status", key: "statusText", width: 800)], datasource: [], selectIndex: -1)
        
        init() {
            logger.info("keys del state init ...")
        }
    }
    
    enum Action: Equatable {
        case initial([RedisKeyModel])
        case setValue([KeyDelModel])
        case deleting
        case delKey(Int)
        case delStatus(Int, Int)
        case refresh
        case tableAction(TableStore.Action)
    }
    
    @Dependency(\.redisClient) var redisClient:RediStackClient
    @Dependency(\.redisInstance) var redisInstanceModel:RedisInstanceModel
    
    
    var body: some Reducer<State, Action> {
        Scope(state: \.tableState, action: /Action.tableAction) {
            TableStore()
        }
        Reduce { state, action in
            switch action {
                // 初始化已设置的值
            case let .initial(keys):
                
                logger.info("key del store initial...")
                let keysDel = keys.map { KeyDelModel($0)}
                return .run { send in
                    await send(.setValue(keysDel))
                }
                
            case let .setValue(keys):
                state.tableState.datasource = keys
                return .none
                
            case .deleting:
                let keys = state.tableState.datasource as! [KeyDelModel]
                
                return .run { send in
                    for (index, _) in keys.enumerated() {
                        await send(.delKey(index))
                    }
                }
              
            case let .delKey(index):
                
                let keyModel = state.tableState.datasource[index] as! KeyDelModel
                
                return .run { send in
                    let r = await redisInstanceModel.getClient().del(keyModel.key)
                    await send(.delStatus(index, r == 0 ? -1 : r))
                }
                
                
            case let .delStatus(index, status):
                let key = state.tableState.datasource[index] as! KeyDelModel
                key.status = status
                
                state.tableState.datasource[index] = key
                return .none
                
            case .refresh:
                return .none
                
            case .tableAction:
                return .none
            }
        }
    }
    
}

