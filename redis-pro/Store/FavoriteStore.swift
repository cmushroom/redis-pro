//
//  Redis.swift
//  redis-pro
//
//  Created by chengpan on 2022/4/30.
//
import Logging
import Foundation
import ComposableArchitecture

struct FavoriteState: Equatable {
    var globalState: GlobalState?
    var tableState: TableState = TableState(columns: [NTableColumn(title: "FAVORITES", key: "name", width: 50, icon: .APP)], datasource: [], selectIndex: -1, dragable: true)
    var loginState: LoginState = LoginState()
    
//    init(globalState: GlobalState) {
//        self.globalState = globalState
//        self.tableState = TableState(columns: [NTableColumn(title: "FAVORITES", key: "name", width: 50, icon: .APP)], datasource: [], selectIndex: -1)
//        self.loginState = LoginState()
//    }
}

enum FavoriteAction:Equatable {
    case getAll
    case addNew
    case save(RedisModel)
    case deleteConfirm(Int)
    case delete(Int)
    case connect(Int)
    case connectSuccess(RedisModel)
    case initDefaultSelection
    case tableAction(TableAction)
    case loginAction(LoginAction)
    case loadingAction(LoadingAction)
    case none
}

struct FavoriteEnvironment {
    var redisInstanceModel:RedisInstanceModel
    var mainQueue: AnySchedulerOf<DispatchQueue> = .main
}

private let logger = Logger(label: "redis-favorite-store")
let favoriteReducer = Reducer<FavoriteState, FavoriteAction, FavoriteEnvironment>.combine(
    tableReducer.pullback(
      state: \.tableState,
      action: /FavoriteAction.tableAction,
      environment: { _ in TableEnvironment() }
    ),
    loginReducer.pullback(
      state: \.loginState,
      action: /FavoriteAction.loginAction,
      environment: { env in LoginEnvironment(redisInstanceModel: env.redisInstanceModel) }
    ),
    Reducer<FavoriteState, FavoriteAction, FavoriteEnvironment> {
        state, action, env in
        switch action {
        // 查询所有收藏
        case .getAll:
            state.tableState.datasource = RedisDefaults.getAll()
//            state.tableState.defaultSelectIndex = 1
            return .none
        // 设置默认选中
        case .initDefaultSelection:
            var selectId:String?
            let defaultFavorite = RedisDefaults.defaultSelectType()
            if defaultFavorite == "last" {
                selectId = RedisDefaults.getLastId()
            } else {
                selectId = defaultFavorite
            }
            
            guard let selectId = selectId else {
                state.tableState.defaultSelectIndex = state.tableState.datasource.count > 0 ? 0 : -1
                return .none
            }
            
            if let index = state.tableState.datasource.firstIndex(where: { (e) -> Bool in
                return (e as! RedisModel).id == selectId
            }) {
                state.tableState.defaultSelectIndex = index
                return .none
            }
            
            state.tableState.defaultSelectIndex = state.tableState.datasource.count > 0 ? 0 : -1
            return .none
        case .addNew:
            return .result {
                .success(.save(RedisModel()))
            }
        case let .save(redisModel):
            logger.info("save redis favorite: \(redisModel)")
            
            let index = RedisDefaults.save(redisModel)
            state.tableState.selectIndex = index
            return .result {
                .success(.getAll)
            }
        case let .deleteConfirm(index):
            if state.tableState.datasource.count <= index {
                return .none
            }
            
            let redisModel = state.tableState.datasource[index] as! RedisModel
            
            return Effect<FavoriteAction, Never>.future { callback in
                Messages.confirm(String(format: NSLocalizedString("CONFIRM_FAVORITE_REDIS_TITLE'%@'", comment: ""), redisModel.name)
                                  , message: String(format: NSLocalizedString("CONFIRM_FAVORITE_REDIS_MESSAGE'%@'", comment: ""), redisModel.name)
                                  , primaryButton: "Delete"
                                  , action: {
                    callback(.success(.delete(index)))
                }
                )
            }
        case let .delete(index):
            let r = RedisDefaults.delete(index)
            if r {
                state.tableState.datasource.remove(at: index)
                if state.tableState.datasource.count - 1 < state.tableState.selectIndex {
                    state.tableState.selectIndex = state.tableState.datasource.count - 1
                }
            }
            logger.info("delete redis favorite")
            return .none
        // login
        case let .connect(index):
            let redisModel = state.tableState.datasource[index] as! RedisModel
            logger.info("connect to redis server, name: \(redisModel.name), host: \(redisModel.host)")
            
            return Effect<FavoriteAction, Never>.task {
                let r = await env.redisInstanceModel.connect(redisModel:redisModel)
                logger.info("on connect to redis server: \(redisModel) , result: \(r)")
                RedisDefaults.saveLastUse(redisModel)
                return r ? .connectSuccess(redisModel) : .none
            }
            .receive(on: env.mainQueue)
            .eraseToEffect()

        
        case let .tableAction(.dragComplete(from, to)):
            let _ = RedisDefaults.save(state.tableState.datasource as! [RedisModel])
            return .none
            
        case let .tableAction(.double(index)):
            return .result {
                .success(.connect(index))
            }
        case let .tableAction(.selectionChange(index)):
            guard index > -1 else { return .none }
            
            logger.info("redis favorite table selection change action, index: \(index)")
            let redisModel = state.tableState.datasource[index] as! RedisModel
            state.loginState.redisModel = redisModel
            return .none
        case let .tableAction(.delete(index)):
            return .result {
                .success(.deleteConfirm(index))
            }
        case .tableAction:
            logger.info("redis favorite table action \(state.tableState.selectIndex)")
            return .none
            
        case .loginAction(.connect):
            let index = state.tableState.selectIndex
            return .result {
                .success(.connect(index))
            }
        case .loginAction(.save):
            let redisModel = state.loginState.redisModel
            return .result {
                .success(.save(redisModel))
            }
        case .loginAction:
            logger.info("redis favorite table action \(state.tableState.selectIndex)")
            return .none
        case .loadingAction:
            return .none
        case .connectSuccess:
            return .none
        case .none:
            return .none
        }
    }
)
