//
//  RedisLoginStore.swift
//  redis-pro
//
//  Created by chengpan on 2022/5/1.
//

import Logging
import Foundation
import ComposableArchitecture

private let logger = Logger(label: "login-store")

struct LoginStore: Reducer {
    
    struct State: Equatable {
        var id: String = ""
        @BindingState var name:String = ""
        @BindingState var host: String = "127.0.0.1"
        @BindingState var port: Int = 6379
        @BindingState var database: Int = 0
        @BindingState var username: String = ""
        @BindingState var password: String = ""
        @BindingState var connectionType:String = "tcp"
        
        // ssh
        @BindingState var sshHost:String = ""
        @BindingState var sshPort:Int = 22
        @BindingState var sshUser:String = ""
        @BindingState var sshPass:String = ""
        
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
                redisModel.username = username
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
                self.username = n.username
                self.password = n.password
                self.connectionType = n.connectionType
                self.sshHost = n.sshHost
                self.sshPort = n.sshPort
                self.sshUser = n.sshUser
                self.sshPass = n.sshPass
            }
        }
    }

    enum Action:BindableAction,Equatable {
        case add
        case save
        case testConnect
        case connect
        case setPingR(Bool)
        case none
        case binding(BindingAction<State>)
    }
    
    @Dependency(\.redisInstance) var redisInstanceModel:RedisInstanceModel
    @Dependency(\.redisClient) var redisClient: RediStackClient
    @Dependency(\.appContext) var appContext: StoreOf<AppContextStore>
    
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .add:
                state.id = UUID().uuidString
                return .run { send in
                    await send(.save)
                }
            case .save:
                return .none
            case .testConnect:
                logger.info("test connect to redis server, name: \(state.name), host: \(state.host)")
                state.loading = true
                let redis = state.redisModel
                
                return .run { send in
                    let r = await redisInstanceModel.testConnect(redis)
                    await send(.setPingR(r))
                    await send(.setPingR(r))
                    
                }
            case let .setPingR(r):
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
        }
    }
}
