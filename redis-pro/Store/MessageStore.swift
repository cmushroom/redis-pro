//
//  MessageStore.swift
//  redis-pro
//
//  Created by chengpan on 2022/5/29.
//

import Logging
import Foundation
import ComposableArchitecture

private let logger = Logger(label: "alert-store")

struct MessageState: Equatable {
    
    var alert: AlertState<MessageAction>?
    var action: (() -> Void)?
    
    init() {
        logger.info("message state init ...")
    }
    
    static func == (lhs: MessageState, rhs: MessageState) -> Bool {
        lhs.alert == rhs.alert
    }
}

enum MessageAction: Equatable {
    static func == (lhs: MessageAction, rhs: MessageAction) -> Bool {
        lhs.value == rhs.value
    }
    
    var value: String? {
        return String(describing: self).components(separatedBy: "(").first
    }
    
    case alert
    case error(String)
    case confirm(String, String, String, (() -> Void))
    case doAction
    case clearAlert
    case ok
    case cancel
    case none
}

struct MessageEnvironment {
}


let messageReducer = Reducer<MessageState, MessageAction, MessageEnvironment>.combine(
    Reducer<MessageState, MessageAction, MessageEnvironment> {
        state, action, _ in
        switch action {
        case .alert:
            state.alert = .init(
                title: TextState("Delete"),
                message: TextState("Are you sure you want to delete this? It cannot be undone."),
                primaryButton: .default(TextState("Confirm"), action: .send(.none)),
                secondaryButton: .cancel(TextState("Cancel"))
            )
            return .none
        case let .error(message):
            state.alert = .init(
                title: TextState("Error!"),
                message: TextState(message),
                dismissButton: .default(TextState("Ok"))
            )
            return .none
        case let .confirm(title, message, primaryButton, action):
            state.action = action
            state.alert = .init(
                title: TextState(title),
                message: TextState(message),
                primaryButton: .default(TextState(primaryButton), action: .send(.doAction)),
                secondaryButton: .cancel(TextState("Cancel"))
            )
            return .none
        case .doAction:
            state.action?()
            state.action = nil
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
        case .none:
            return .none
        }
    }.debug()
)
