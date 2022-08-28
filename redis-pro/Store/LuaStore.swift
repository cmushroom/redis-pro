//
//  LuaStore.swift
//  redis-pro
//
//  Created by chengpan on 2022/7/17.
//

import Logging
import Foundation
import ComposableArchitecture

struct LuaState: Equatable {
    @BindableState var lua:String = "\"return {KEYS[1],KEYS[2],ARGV[1],ARGV[2]}\" 2 key1 key2 arg1 arg2"
    @BindableState var evalResult:String = ""
    var luaSHA: String = "-"
}

enum LuaAction:BindableAction,Equatable {
    case eval
    case scriptKill
    case scriptFlush
    case scriptLoad
    case setLuaResult(String)
    case setLuaSHA(String)
    case none
    case binding(BindingAction<LuaState>)
}

struct LuaEnvironment {
    var redisInstanceModel:RedisInstanceModel
}

private let logger = Logger(label: "lua-store")
let luaReducer = Reducer<LuaState, LuaAction, SystemEnvironment<LuaEnvironment>> {
    state, action, env in
    switch action {
        
    case .eval:
        let lua = state.lua
        return .task {
            let r = await env.redisInstanceModel.getClient().eval(lua)
            return .setLuaResult(r)
        }
        .receive(on: env.mainQueue)
        .eraseToEffect()
        
    case .scriptKill:
        
        return .task {
            let _ = await env.redisInstanceModel.getClient().scriptKill()
            return .none
        }
        .receive(on: env.mainQueue)
        .eraseToEffect()
        
    case .scriptFlush:
        
        return .task {
            let _ = await env.redisInstanceModel.getClient().scriptFlush()
            return .none
        }
        .receive(on: env.mainQueue)
        .eraseToEffect()
        
    case .scriptLoad:
        
        let lua = state.lua
        return .task {
            return .setLuaSHA("")
        }
        .receive(on: env.mainQueue)
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
}.binding().debug()
