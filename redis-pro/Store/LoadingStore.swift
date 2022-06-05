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

struct LoadingState: Equatable {
    var loading: Bool = false
    
    init() {
        logger.info("loading state init ...")
    }
}

enum LoadingAction:Equatable {
    case show
    case hide
}

struct LoadingEnvironment {
    //    var redisInstanceModel:RedisInstanceModel = RedisInstanceModel(redisModel: RedisModel())
}


let loadingReducer = Reducer<LoadingState, LoadingAction, LoadingEnvironment>.combine(
    Reducer<LoadingState, LoadingAction, LoadingEnvironment> {
        state, action, _ in
        switch action {
        case .show:
            state.loading = true
            return .none
        case .hide:
            state.loading = false
            return .none
        }
    }.debug()
)
