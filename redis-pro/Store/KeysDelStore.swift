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
        var pageState: PageStore.State = PageStore.State()
        var tableState: TableStore.State = TableStore.State(columns: [.init(title: "Type", key: "type", width: 120), .init(title: "Key", key: "key", width: 100), .init(title: "Status", key: "statusText", width: 800)], datasource: [], selectIndex: -1)
        
        init() {
            logger.info("keys del state init ...")
        }
    }
    
    enum Action: Equatable {
        case initial
        case search(String)
        case refresh
        case setValue([KeyDelModel])
        case doDel
        case delKey(Int)
        case delStatus(Int, Int)
        case tableAction(TableStore.Action)
        case pageAction(PageStore.Action)
    }
    
    @Dependency(\.redisClient) var redisClient:RediStackClient
    
    var body: some Reducer<State, Action> {
        Scope(state: \.tableState, action: /Action.tableAction) {
            TableStore()
        }
        Reduce { state, action in
            switch action {

            case .initial:
                return .run { send in
                    await send(.search(""))
                }
            case let .search(keywords):
                
                state.pageState.current = 1
                state.pageState.total = 0
                state.pageState.keywords = keywords
                
                let page = state.pageState.page
                return .run { send in
                    let keysPage = await redisClient.pageKeys(page)
                    await send(.setValue(keysPage.map({KeyDelModel($0)})))
                }
                
            case .refresh:
                return .none
                
            case let .setValue(keys):
                state.tableState.datasource = keys
                return .none
                
            case .doDel:
                let keys = state.tableState.datasource as! [KeyDelModel]
                
                return .run { send in
                    for (index, _) in keys.enumerated() {
                        await send(.delKey(index))
                    }
                }
                
            case let .delKey(index):
                
                let keyModel = state.tableState.datasource[index] as! KeyDelModel
                
                return .run { send in
                    let r = await redisClient.del(keyModel.key)
                    await send(.delStatus(index, r == 0 ? -1 : r))
                }
                
                
            case let .delStatus(index, status):
                let key = state.tableState.datasource[index] as! KeyDelModel
                key.status = status
                
                state.tableState.datasource[index] = key
                return .none
                
            case .tableAction:
                return .none
            case .pageAction:
                return .none
            }
        }
    }
    
}

