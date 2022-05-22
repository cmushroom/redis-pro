//
//  ValueStore.swift
//  redis-pro
//
//  Created by chengpanwang on 2022/5/6.
//


import Logging
import Foundation
import ComposableArchitecture

private let logger = Logger(label: "value-store")
struct ValueState: Equatable {
    var mainViewType: MainViewTypeEnum = .EDITOR
    var keyState: KeyState = KeyState()
    var stringValueState: StringValueState = StringValueState()
    var hashValueState: HashValueState = HashValueState()
    var listValueState: ListValueState = ListValueState()
    var setValueState: SetValueState = SetValueState()
    
    init() {
        logger.info("value state init ...")
    }
}


enum ValueAction:BindableAction, Equatable {
    case initial
    case refresh
    case none
    case keyChange(RedisKeyModel)
    case submitSuccess(Bool)
    case keyAction(KeyAction)
    case stringValueAction(StringValueAction)
    case hashValueAction(HashValueAction)
    case listValueAction(ListValueAction)
    case setValueAction(SetValueAction)
    case binding(BindingAction<ValueState>)
}

struct ValueEnvironment {
    var redisInstanceModel:RedisInstanceModel
}

let valueReducer = Reducer<ValueState, ValueAction, ValueEnvironment>.combine(
    keyReducer.pullback(
        state: \.keyState,
        action: /ValueAction.keyAction,
        environment: { env in .init(redisInstanceModel: env.redisInstanceModel) }
    ),
    stringValueReducer.pullback(
        state: \.stringValueState,
        action: /ValueAction.stringValueAction,
        environment: { env in .init(redisInstanceModel: env.redisInstanceModel) }
    ),
    hashValueReducer.pullback(
        state: \.hashValueState,
        action: /ValueAction.hashValueAction,
        environment: { env in .init(redisInstanceModel: env.redisInstanceModel) }
    ),
    listValueReducer.pullback(
        state: \.listValueState,
        action: /ValueAction.listValueAction,
        environment: { env in .init(redisInstanceModel: env.redisInstanceModel) }
    ),
    setValueReducer.pullback(
        state: \.setValueState,
        action: /ValueAction.setValueAction,
        environment: { env in .init(redisInstanceModel: env.redisInstanceModel) }
    ),
    Reducer<ValueState, ValueAction, ValueEnvironment> {
        state, action, env in
        switch action {
        // 初始化已设置的值
        case .initial:
            logger.info("value store initial...")
            return .none
            
        case .refresh:
            return .result {
                .success(.keyAction(.getTtl))
            }
            
        case .none:
            return .none
        
        // key 变化统计走此action 分发
        case let .keyChange(redisKeyModel):
            state.keyState.redisKeyModel = redisKeyModel
            
            var valueAction:ValueAction = .stringValueAction(.initial)
            
            if redisKeyModel.type == RedisKeyTypeEnum.STRING.rawValue {
                state.stringValueState.redisKeyModel = redisKeyModel
            } else if redisKeyModel.type == RedisKeyTypeEnum.HASH.rawValue {
                state.hashValueState.redisKeyModel = redisKeyModel
                valueAction = .hashValueAction(.initial)
            } else if redisKeyModel.type == RedisKeyTypeEnum.LIST.rawValue {
                state.listValueState.redisKeyModel = redisKeyModel
                valueAction = .listValueAction(.initial)
            } else if redisKeyModel.type == RedisKeyTypeEnum.SET.rawValue {
                state.setValueState.redisKeyModel = redisKeyModel
                valueAction = .setValueAction(.initial)
            }
            
            return .merge(
                .result {
                    .success(.keyAction(.refresh))
                },
                .result {
                    .success(valueAction)
                }
            )
            
        // 各个编辑器成功后调用此action
        case let .submitSuccess(isNew):
            if isNew {
                state.keyState.isNew = false
            }
            return .result {
                .success(.keyAction(.refresh))
            }
            
        case .keyAction(.setType):
            let redisKeyModel = state.keyState.redisKeyModel
            return .result {
                .success(.keyChange(redisKeyModel))
            }
            
        case .keyAction:
            return .none
            
        // submit 成功后统一调用 submitSuccess, 此后的动作再依次分发
        case let .stringValueAction(.submitSuccess(isNew)):
            return .result {
                .success(.submitSuccess(isNew))
            }
            
        case .stringValueAction(.refresh):
            return .result {
                .success(.refresh)
            }
            
        case .stringValueAction:
            return .none
            
        case .hashValueAction(.refresh):
            return .result {
                .success(.refresh)
            }
            
        case let .hashValueAction(.submitSuccess(isNew)):
            return .result {
                .success(.submitSuccess(isNew))
            }
        case .hashValueAction:
            return .none
            
        case .listValueAction(.refresh):
            return .result {
                .success(.refresh)
            }
        case .listValueAction:
            return .none
            
        case .setValueAction(.refresh):
            return .result {
                .success(.refresh)
            }
        case .setValueAction:
            return .none
        case .binding:
            return .none
        }
    }
).binding().debug()
