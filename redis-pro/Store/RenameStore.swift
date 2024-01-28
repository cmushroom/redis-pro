//
//  RenameStore.swift
//  redis-pro
//
//  Created by chengpan on 2022/5/14.
//

import Logging
import Foundation
import ComposableArchitecture

private let logger = Logger(label: "rename-store")

struct RenameStore: Reducer {
    struct State: Equatable {
        var key:String = ""
        var index:Int = -1
        var visible:Bool = false
        @BindingState var newKey:String = ""
        
        init() {
            logger.info("string value state init ...")
        }
    }

    enum Action:BindableAction, Equatable {
        case initial
        case submit
        case setKey(Int, String)
        case setNewKey(String)
        case hide
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
                
                logger.info("rename store initial...")
                return .none
            case .hide:
                state.visible = false
                return .none
            case .submit:
                let key = state.key
                let index = state.index
                let newKey = state.newKey
                return .run { send in
                    
                    let r = await redisInstanceModel.getClient().rename(key, newKey: newKey)
                    if r {
                        await send(.setKey(index, newKey))
                    }
                }
                
            case let .setKey(index, newKey):
                state.visible = false
                return .none
            
            case let .setNewKey(newKey):
                state.newKey = newKey
                return .none
            case .none:
                return .none
                
            case .binding:
                return .none
            }
        }
    }
    
    
}
