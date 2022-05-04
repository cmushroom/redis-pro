//
//  AlertStore.swift
//  redis-pro
//
//  Created by chengpan on 2022/5/3.
//


import Logging
import Foundation
import ComposableArchitecture

private let logger = Logger(label: "alert-store")

struct AppAlertState: Equatable {
    var alert: AlertState<AlertAction>?

    init() {
        logger.info("alert state init ...")
    }
}

enum AlertAction:Equatable {
    case alert
    case clearAlert
    case ok
    case cancel
    case confirm
}

struct AlertEnvironment {
//    var redisInstanceModel:RedisInstanceModel = RedisInstanceModel(redisModel: RedisModel())
}


let alertReducer = Reducer<AppAlertState, AlertAction, AlertEnvironment>.combine(
    Reducer<AppAlertState, AlertAction, AlertEnvironment> {
        state, action, _ in
        switch action {
        case .alert:
            state.alert = .init(
                    title: TextState("Delete"),
                    message: TextState("Are you sure you want to delete this? It cannot be undone."),
                    primaryButton: .default(TextState("Confirm"), action: .send(.confirm)),
                    secondaryButton: .cancel(TextState("Cancel"))
                  )
            return .none
        case .clearAlert:
            state.alert = nil
            return .none
        case .ok:
            print("ok")
            return .none
        case .cancel:
            print("cancel")
            return .none
        case .confirm:
            print("confirm....")
            return .none
        }
    }.debug()
)
