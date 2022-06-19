//
//  RedisLoginStore.swift
//  redis-pro
//
//  Created by chengpan on 2022/5/1.
//

import Logging
import Foundation
import ComposableArchitecture

struct LoginState: Equatable {    
    var id: String = ""
    @BindableState var name:String = ""
    @BindableState var host: String = "127.0.0.1"
    @BindableState var port: Int = 6379
    @BindableState var database: Int = 0
    @BindableState var user: String = "default"
    @BindableState var password: String = ""
    @BindableState var connectionType:String = "tcp"
    
    // ssh
    @BindableState var sshHost:String = ""
    @BindableState var sshPort:Int = 22
    @BindableState var sshUser:String = ""
    @BindableState var sshPass:String = ""
    
    var pingR: String = ""
    var loading: Bool = false
    
    var height:CGFloat {
        connectionType == RedisConnectionTypeEnum.SSH.rawValue ? 500 : 380
    }
    
    // 方便外部使用
    var redisModel:RedisModel {
        get {
            let redisModel = RedisModel(name: name)
            redisModel.id = id
            redisModel.host = host
            redisModel.port = port
            redisModel.database = database
            redisModel.user = user
            redisModel.password = password
            redisModel.connectionType = connectionType
            redisModel.sshHost = sshHost
            redisModel.sshPort = sshPort
            redisModel.sshUser = sshUser
            redisModel.sshPass = sshPass
            
            return redisModel
        }
        set(n) {
            self.id = n.id
            self.name = n.name
            self.host = n.host
            self.port = n.port
            self.database = n.database
            self.user = n.user
            self.password = n.password
            self.connectionType = n.connectionType
            self.sshHost = n.sshHost
            self.sshPort = n.sshPort
            self.sshUser = n.sshUser
            self.sshPass = n.sshPass
        }
    }
}

enum LoginAction:BindableAction,Equatable {
    case add
    case save
    case testConnect
    case connect
    case ping(Bool)
    case none
    case binding(BindingAction<LoginState>)
}

struct LoginEnvironment {
    var redisInstanceModel:RedisInstanceModel
    var mainQueue: AnySchedulerOf<DispatchQueue> = .main
}



private let logger = Logger(label: "login-store")
let loginReducer = Reducer<LoginState, LoginAction, LoginEnvironment> {
    state, action, env in
    switch action {
    case .add:
        state.id = UUID().uuidString
        return .result {
            .success(.save)
        }
    case .save:
        return .none
    case .testConnect:
        logger.info("test connect to redis server, name: \(state.name), host: \(state.host)")
        state.loading = true
        let redis = state.redisModel
        
        return Effect<LoginAction, Never>.task {
            let r = await env.redisInstanceModel.testConnect(redis)
            return .ping(r)
        }
        .receive(on: env.mainQueue)
        .eraseToEffect()
    case let .ping(r):
        state.pingR =  r ? "Connect successed!" : "Connect fail! "
        state.loading = false
        return .none
    case .connect:
        return .none
    case .none:
        return .none
    case .binding:
        return .none
    }
}.binding().debug()
