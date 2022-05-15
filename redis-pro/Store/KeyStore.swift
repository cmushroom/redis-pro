//
//  KeyStore.swift
//  redis-pro
//
//  Created by chengpanwang on 2022/5/6.
//
import Logging
import Foundation
import ComposableArchitecture

private let logger = Logger(label: "key-store")

struct KeyState: Equatable {
    @BindableState var type: String = RedisKeyTypeEnum.STRING.rawValue
    @BindableState var key: String = ""
    var ttl: Int = -1

    var isNew: Bool = false
    
    var redisKeyModel:RedisKeyModel {
        get {
            let r = RedisKeyModel()
            r.type = type
            r.key = key
            r.isNew = isNew
            return r
        }
        set(n) {
            type = n.type
            key = n.key
            isNew = n.isNew
        }
    }
    
    init() {
        logger.info("key state init ...")
    }
}


enum KeyAction:BindableAction, Equatable {
    case initial
    case refresh
    case updateKey(String)
    case getTtl
    case submit
    case saveTtl
    case setTtl(Int)
    case setType(String)
    case none
    case binding(BindingAction<KeyState>)
}

struct KeyEnvironment {
    var redisInstanceModel:RedisInstanceModel
    var mainQueue: AnySchedulerOf<DispatchQueue> = .main
}

let keyReducer = Reducer<KeyState, KeyAction, KeyEnvironment>.combine(
    Reducer<KeyState, KeyAction, KeyEnvironment> {
        state, action, env in
        switch action {
        // 初始化已设置的值
        case .initial:
            logger.info("key store initial...")
            return .none
            
        case .refresh:
            return .result {
                .success(.getTtl)
            }
            
        case let .updateKey(key):
            state.key = key
            return .none
        case .getTtl:
            if state.isNew {
                state.ttl = -1
                return .none
            }
            
            let key = state.key
            return .task {
                let r = await env.redisInstanceModel.getClient().ttl(key)
                return .setTtl(r)
            }
            .receive(on: env.mainQueue)
            .eraseToEffect()
        case let .setTtl(ttl):
            state.ttl = ttl
            return .none
        
        case .submit:
            return .result {
                .success(.saveTtl)
            }
            
        case .saveTtl:
            if state.isNew {
                return .none
            }
            logger.info("update redis key ttl: \(state.redisKeyModel)")
            
            let key = state.key
            let ttl = state.ttl
            return Effect<KeyAction, Never>.task {
                let _ = await env.redisInstanceModel.getClient().expire(key, seconds: ttl)
                return .none
            }
            .receive(on: env.mainQueue)
            .eraseToEffect()
            
        case let .setType(type):
            state.type = type
            return .none
        case .none:
            return .none
        case .binding:
            return .none
        }
    }
).binding().debug()
