//
//  GlobalStore.swift
//  redis-pro
//
//  Created by chengpan on 2022/6/2.
//


import Logging
import Foundation
import ComposableArchitecture

private let logger = Logger(label: "app-context-store")


struct AppContextStore: Reducer {
    struct State: Equatable {
        var loading:Bool = false
        var loadingCount:Int = 0
        
        init() {
            logger.info("app context state init ...")
        }
    }

    enum Action: Equatable {
        case show
        case hide
    }
    
    var body: some Reducer<State, Action> {
        
        Reduce { state, action in
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
        }
    }
}
