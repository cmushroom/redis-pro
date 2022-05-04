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
    @BindableState var password: String = ""
    @BindableState var connectionType:String = "tcp"
    
    // ssh
    @BindableState var sshHost:String = ""
    @BindableState var sshPort:Int = 22
    @BindableState var sshUser:String = ""
    @BindableState var sshPass:String = ""
    
    var pingR: String = ""
    
    var height:CGFloat {
        connectionType == RedisConnectionTypeEnum.SSH.rawValue ? 500 : 380
    }
    
    // 方便外部使用
    var redisModel:RedisModel {
        get {
            let redisModel = RedisModel(name: name)
            redisModel.host = host
            redisModel.port = port
            redisModel.database = database
            redisModel.password = password
            redisModel.connectionType = connectionType
            redisModel.sshHost = sshHost
            redisModel.sshPort = sshPort
            redisModel.sshUser = sshUser
            redisModel.sshPass = sshPass
            
            return redisModel
        }
        set(n) {
            self.name = n.name
            self.host = n.host
            self.port = n.port
            self.database = n.database
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
    case login
    case testConnect
    case ping(Bool)
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
        // login redis server
    case .login:
        logger.info("login action ...")
        return .none
    case .testConnect:
        logger.info("test connect to redis server, name: \(state.name), host: \(state.host)")
        let redis = state.redisModel
        
        return Effect<LoginAction, Never>.task {
            let r = await env.redisInstanceModel.testConnect(redis)
            return .ping(r)
        }
        .receive(on: env.mainQueue)
        .eraseToEffect()
    case let .ping(r):
        state.pingR =  r ? "Connect successed!" : "Connect fail! "
        return .none
    case .binding:
        return .none
    }
}.binding().debug()
