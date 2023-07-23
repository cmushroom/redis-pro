//
//  DependencyKeys.swift
//  redis-pro
//
//  Created by chengpan on 2023/7/2.
//

import Foundation
import Dependencies

private enum RedisInstanceKey: DependencyKey {
    static let liveValue = RedisInstanceModel(redisModel: RedisModel())
}

private enum RedisClientKey: DependencyKey {
    static let liveValue = RediStackClient(RedisModel())
}


//private enum AppContextKey: DependencyKey {
//    static let liveValue = AppContext()
//}


extension DependencyValues {
    var redisInstance: RedisInstanceModel {
        get { self[RedisInstanceKey.self] }
        set { self[RedisInstanceKey.self] = newValue }
    }
    
    var redisClient: RediStackClient {
        get { self[RedisClientKey.self] }
        set { self[RedisClientKey.self] = newValue }
    }
    
    //    var appContext: AppContext {
    //      get { self[AppContextKey.self] }
    //      set { self[AppContextKey.self] = newValue }
    //    }
}
