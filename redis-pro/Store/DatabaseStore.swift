//
//  DatabaseStore.swift
//  redis-pro
//
//  Created by chengpanwang on 2022/5/6.
//

import Logging
import Foundation
import ComposableArchitecture

private let logger = Logger(label: "database-store")

struct DatabaseState: Equatable {
    var database: Int = 0
    var databases:Int = 16

    init() {
        logger.info("database state init ...")
    }
}


enum DatabaseAction:BindableAction, Equatable {
    case initial
    case getDatabases
    case updateDatabases(Int)
    case change(Int)
    case none
    case binding(BindingAction<DatabaseState>)
}

struct DatabaseEnvironment {
    var redisInstanceModel:RedisInstanceModel
    var mainQueue: AnySchedulerOf<DispatchQueue> = .main
}

let databaseReducer = Reducer<DatabaseState, DatabaseAction, DatabaseEnvironment>.combine(
    Reducer<DatabaseState, DatabaseAction, DatabaseEnvironment> {
        state, action, env in
        switch action {
        // 初始化已设置的值
        case .initial:
            logger.info("database store initial...")
            state.database = env.redisInstanceModel.redisModel.database
            return .result {
                .success(.getDatabases)
            }
        case .getDatabases:
            return .task {
                let r = await env.redisInstanceModel.getClient().databases()
                return .updateDatabases(r)
            }
            .receive(on: env.mainQueue)
            .eraseToEffect()
        case let .updateDatabases(databases):
            state.databases = databases
            return .none
        case let .change(database):
            state.database = database
            return .none
        case .none:
            return .none
        case .binding:
            return .none
        }
    }
).binding().debug()
