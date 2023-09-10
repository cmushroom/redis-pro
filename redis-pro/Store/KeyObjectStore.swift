//
//  ObjectEncodingStore.swift
//  redis-pro
//
//  Created by chengpan on 2023/7/23.
//

import Logging
import Foundation
import ComposableArchitecture

private let logger = Logger(label: "key-object-store")

struct KeyObjectStore: Reducer {
    
    struct State: Equatable {
        var key: String = ""
        var encoding: String = ""

        var redisKeyModel:RedisKeyModel {
            get {
                let r = RedisKeyModel()
                r.key = key
                return r
            }
            set(n) {
                key = n.key
            }
        }
        
        init() {
            logger.info("key object init ...")
        }
    }


    enum Action: Equatable {
        case initial
        case refresh
        case setKey(String)
        case getEncoding
        case setEncoding(String)
    }
    
    @Dependency(\.redisInstance) var redisInstanceModel:RedisInstanceModel
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            // 初始化已设置的值
            case .initial:
                logger.info("key object initial...")
                return .none
                
            case .refresh:
                return .run { send in
                    await send(.getEncoding)
                }
                
            case let .setKey(key):
                state.key = key
                return .none
                
            case .getEncoding:
                let key = state.key
                return .run { send in
                    let r = await redisInstanceModel.getClient().objectEncoding(key)
                    return await send(.setEncoding(r))
                }
                
            case let .setEncoding(encoding):
                state.encoding = encoding
                return .none
            }
        }
    }
}
