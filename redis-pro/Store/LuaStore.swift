//
//  LuaStore.swift
//  redis-pro
//
//  Created by chengpan on 2022/7/17.
//

import Logging
import Foundation
import ComposableArchitecture


struct LuaStore: Reducer {
    
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
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
            case .eval:
                let lua = state.lua
                return .run { send in
                    let r = await redisInstanceModel.getClient().eval(lua)
                    await send(.setLuaResult(r))
                }
                
            case .scriptKill:
                
                return .run { send in
                    let _ = await redisInstanceModel.getClient().scriptKill()
                }
                
            case .scriptFlush:
                
                return .run { send in
                    let _ = await redisInstanceModel.getClient().scriptFlush()
                }
                
            case .scriptLoad:
                
                let lua = state.lua
                return .run { send in
                    await send(.setLuaSHA(""))
                }
                
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
