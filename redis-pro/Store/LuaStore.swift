//
//  LuaStore.swift
//  redis-pro
//
//  Created by chengpan on 2022/7/17.
//

import Logging
import Foundation
import ComposableArchitecture


struct LuaStore: ReducerProtocol {
    
    struct State: Equatable {
        @BindingState var lua:String = "\"return {KEYS[1],KEYS[2],ARGV[1],ARGV[2]}\" 2 key1 key2 arg1 arg2"
        @BindingState var evalResult:String = ""
        var luaSHA: String = "-"
    }

    enum Action:BindableAction,Equatable {
        case eval
        case scriptKill
        case scriptFlush
        case scriptLoad
        case setLuaResult(String)
        case setLuaSHA(String)
        case none
        case binding(BindingAction<State>)
    }
    
    @Dependency(\.redisInstance) var redisInstanceModel:RedisInstanceModel
    let mainQueue: AnySchedulerOf<DispatchQueue> = .main
    
    var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
                
            case .eval:
                let lua = state.lua
                return .task {
                    let r = await redisInstanceModel.getClient().eval(lua)
                    return .setLuaResult(r)
                }
                .receive(on: mainQueue)
                .eraseToEffect()
                
            case .scriptKill:
                
                return .task {
                    let _ = await redisInstanceModel.getClient().scriptKill()
                    return .none
                }
                .receive(on: mainQueue)
                .eraseToEffect()
                
            case .scriptFlush:
                
                return .task {
                    let _ = await redisInstanceModel.getClient().scriptFlush()
                    return .none
                }
                .receive(on: mainQueue)
                .eraseToEffect()
                
            case .scriptLoad:
                
                let lua = state.lua
                return .task {
                    return .setLuaSHA("")
                }
                .receive(on: mainQueue)
                .eraseToEffect()
                
            case let .setLuaResult(r):
                state.evalResult = r
                return .none
                
            case let .setLuaSHA(r):
                state.luaSHA = r
                return .none
                
            case .none:
                return .none
            case .binding:
                return .none
            }
        }
    }
}
