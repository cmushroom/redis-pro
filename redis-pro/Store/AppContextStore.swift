//
//  AppContextStore.swift
//  redis-pro
//
//  Created by chengpan on 2022/5/1.
//
import Logging
import Foundation
import ComposableArchitecture

struct AppContextState: Equatable {
    var loading: Bool = false
}

enum AppContextAction {
    case loading(Bool)
}

struct AppContextEnvironment {
    
}

private let logger = Logger(label: "app-store")
let appContextReducer = Reducer<AppContextState, AppContextAction, AppContextEnvironment> {
    state, action, _ in
    switch action {
    case let .loading(loading):
        state.loading = loading
        return .none
    }
}.debug()
