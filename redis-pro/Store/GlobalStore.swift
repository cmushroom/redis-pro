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
            print("show")
            state.loading.toggle()
            return .none
        case .hide:
            print("hide")
            state.loading = false
            return .none
        }
    }.debug()
)
