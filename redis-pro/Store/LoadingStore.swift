//
//  LoadingStore.swift
//  redis-pro
//
//  Created by chengpan on 2022/5/3.
//


import Logging
import Foundation
import ComposableArchitecture

private let logger = Logger(label: "loading-store")

struct LoadingStore: Reducer {
    struct State: Equatable {
        var loading: Bool = false
        
        init() {
            logger.info("loading state init ...")
        }
    }

    enum Action:Equatable {
        case show
        case hide
    }
    
    var body: some Reducer<State, Action> {
        
        Reduce { state, action in
            switch action {
            case .show:
                state.loading = true
                return .none
            case .hide:
                state.loading = false
                return .none
            }
        }
    }
    
}
