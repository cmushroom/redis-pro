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

struct KeyStore: Reducer {
    
    struct State: Equatable {
        @BindingState var type: String = RedisKeyTypeEnum.STRING.rawValue
        @BindingState var key: String = ""
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


    enum Action:BindableAction, Equatable {
        case initial
        case refresh
        case setKey(String)
        case getTtl
        case submit
        case saveTtl
        case setTtl(Int)
        case setType(String)
        case none
        case binding(BindingAction<State>)
    }
    
    @Dependency(\.redisInstance) var redisInstanceModel:RedisInstanceModel
    var mainQueue: AnySchedulerOf<DispatchQueue> = .main
    
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            // 初始化已设置的值
            case .initial:
                logger.info("key store initial...")
                return .none
                
            case .refresh:
                return .run { send in
                    await send(.getTtl)
                }
                
            case let .setKey(key):
                state.key = key
                return .none
            case .getTtl:
                if state.isNew {
                    state.ttl = -1
                    return .none
                }
                
                let key = state.key
                return .run { send in
                    let r = await redisInstanceModel.getClient().ttl(key)
                    await send(.setTtl(r))
                }
            case let .setTtl(ttl):
                state.ttl = ttl
                return .none
            
            case .submit:
                return .run { send in
                    await send(.saveTtl)
                }
                
            case .saveTtl:
                if state.isNew {
                    return .none
                }
                logger.info("update redis key ttl: \(state.redisKeyModel)")
                
                let key = state.key
                let ttl = state.ttl
                return .run { send in
                    let _ = await redisInstanceModel.getClient().expire(key, seconds: ttl)
                }
                
            case let .setType(type):
                state.type = type
                return .none
            case .none:
                return .none
            case .binding:
                return .none
            }
        }
    }
}
