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


struct ValueStore: ReducerProtocol {
    
    struct State: Equatable {
        var keyState: KeyStore.State = KeyStore.State()
        var stringValueState = StringValueStore.State()
        var hashValueState: HashValueStore.State = HashValueStore.State()
        var listValueState: ListValueStore.State = ListValueStore.State()
        var setValueState: SetValueStore.State = SetValueStore.State()
        var zsetValueState: ZSetValueStore.State = ZSetValueStore.State()
        
        init() {
            logger.info("value state init ...")
        }
    }


    enum Action: Equatable {
        case initial
        case refresh
        case none
        case setKeyModel((RedisKeyModel))
        case keyChange(RedisKeyModel)
        case submitSuccess(Bool)
        case keyAction(KeyStore.Action)
        case stringValueAction(StringValueStore.Action)
        case hashValueAction(HashValueStore.Action)
        case listValueAction(ListValueStore.Action)
        case setValueAction(SetValueStore.Action)
        case zsetValueAction(ZSetValueStore.Action)
    }
    
    @Dependency(\.redisInstance) var redisInstanceModel:RedisInstanceModel
    
    var body: some ReducerProtocol<State, Action> {
        Scope(state: \.keyState, action: /Action.keyAction) {
            KeyStore()
        }
        Scope(state: \.stringValueState, action: /Action.stringValueAction) {
            StringValueStore()
        }
        Scope(state: \.hashValueState, action: /Action.hashValueAction) {
            HashValueStore()
        }
        Scope(state: \.listValueState, action: /Action.listValueAction) {
            ListValueStore()
        }
        Scope(state: \.setValueState, action: /Action.setValueAction) {
            SetValueStore()
        }
        Scope(state: \.zsetValueState, action: /Action.zsetValueAction) {
            ZSetValueStore()
        }
        Reduce { state, action in
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
            
            case let .setKeyModel(redisKeyModel):
                state.keyState.redisKeyModel = redisKeyModel
                
                if redisKeyModel.type == RedisKeyTypeEnum.STRING.rawValue {
                    state.stringValueState.redisKeyModel = redisKeyModel
                } else if redisKeyModel.type == RedisKeyTypeEnum.HASH.rawValue {
                    state.hashValueState.redisKeyModel = redisKeyModel
                } else if redisKeyModel.type == RedisKeyTypeEnum.LIST.rawValue {
                    state.listValueState.redisKeyModel = redisKeyModel
                } else if redisKeyModel.type == RedisKeyTypeEnum.SET.rawValue {
                    state.setValueState.redisKeyModel = redisKeyModel
                } else if redisKeyModel.type == RedisKeyTypeEnum.ZSET.rawValue {
                    state.zsetValueState.redisKeyModel = redisKeyModel
                }
                return .none
            // key 变化统计走此action 分发
            case let .keyChange(redisKeyModel):
                state.keyState.redisKeyModel = redisKeyModel
                
                var valueAction:ValueStore.Action = .stringValueAction(.initial)
                
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
                } else if redisKeyModel.type == RedisKeyTypeEnum.ZSET.rawValue {
                    state.zsetValueState.redisKeyModel = redisKeyModel
                    valueAction = .zsetValueAction(.initial)
                }
                
                return .merge(
                    .send(.keyAction(.refresh)),
                    .send(valueAction)
                )
                
            // 各个编辑器成功后调用此action
            case let .submitSuccess(isNew):
                if isNew {
                    state.keyState.isNew = false
                }
                return .result {
                    .success(.keyAction(.refresh))
                }
            
                
            case let .keyAction(.setKey(key)):
                let redisKeyModel = state.keyState.redisKeyModel
                return .result {
                    .success(.setKeyModel(redisKeyModel))
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
            
            // list action
            case .listValueAction(.refresh):
                return .result {
                    .success(.refresh)
                }
                
            case let .listValueAction(.submitSuccess(isNew)):
                return .result {
                    .success(.submitSuccess(isNew))
                }
            case .listValueAction:
                return .none
                
            // set action
            case .setValueAction(.refresh):
                return .result {
                    .success(.refresh)
                }
            case let .setValueAction(.submitSuccess(isNew)):
                return .result {
                    .success(.submitSuccess(isNew))
                }
            case .setValueAction:
                return .none
                
            // zset action
            case let .zsetValueAction(.submitSuccess(isNew)):
                return .result {
                    .success(.submitSuccess(isNew))
                }
            case .zsetValueAction(.refresh):
                return .result {
                    .success(.refresh)
                }
            case .zsetValueAction:
                return .none
            }
        }
    }
    
}
