//
//  GlobalStore.swift
//  redis-pro
//
//  Created by chengpan on 2022/6/2.
//


import Logging
import Foundation
import ComposableArchitecture

private let logger = Logger(label: "global-store")

struct GlobalState: Equatable {
    var loading:Bool = false
    var loadingCount:Int = 0
    
    init() {
        logger.info("global state init ...")
    }
}

enum GlobalAction: Equatable {
    case show
    case hide
}

struct GlobalEnvironment {
}


let globalReducer = Reducer<GlobalState, GlobalAction, GlobalEnvironment>.combine(
    Reducer<GlobalState, GlobalAction, GlobalEnvironment> {
        state, action, _ in
        switch action {
        case .show:
            let loadingCount = state.loadingCount
            if loadingCount <= 0 {
                state.loading = true
            }
            
            state.loadingCount = loadingCount + 1

            return .none
        case .hide:
            let loadingCount = state.loadingCount
            state.loadingCount = min(loadingCount - 1, 0)
            
            if loadingCount <= 0 {
                state.loading = false
            }
            
            return .none
        }
    }.debug()
)


class GlobalStoreContext {
    static var contextDict:[String: ViewStore<GlobalState, GlobalAction>] = [:]
    
    static func setContext(_ id:String?, store: Store<GlobalState, GlobalAction>) {
        guard  let id = id else {
            return
        }
        contextDict[id] = ViewStore(store)
    }
}
