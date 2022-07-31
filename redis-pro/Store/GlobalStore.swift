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
            if state.loadingCount <= 0 {
                state.loading = true
            }
            
            state.loadingCount += 1
            return .none
        case .hide:
            state.loadingCount -= 1
            if state.loadingCount <= 0 {
                state.loading = false
                state.loadingCount = 0
            }
            
            return .none
        }
    }.debug()
)
