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
    var tableState: TableState = TableState(columns: [NTableColumn(title: "FAVORITES", key: "name", width: 50, icon: .APP)], datasource: [], selectIndex: -1)
    var loginState: LoginState = LoginState()
}

enum FavoriteAction:Equatable {
    case getAll
    case save
    case initDefaultSelection
    case tableAction(TableAction)
    case loginAction(LoginAction)
    case loadingAction(LoadingAction)
}

struct FavoriteEnvironment {
    var redisInstanceModel:RedisInstanceModel
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
        state, action, _ in
        switch action {
        // 查询所有收藏
        case .getAll:
            state.tableState.datasource = RedisDefaults.getAll()
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
                state.tableState.selectIndex = state.tableState.datasource.count > 0 ? 0 : -1
                return .none
            }
            
            if let index = state.tableState.datasource.firstIndex(where: { (e) -> Bool in
                return (e as! RedisModel).id == selectId
            }) {
                state.tableState.selectIndex = index
            }
            
            state.tableState.selectIndex = state.tableState.datasource.count > 0 ? 0 : -1
            
            return .none
        case .save:
            return .none
        case let .tableAction(.onSelectionChange(index)):
            logger.info("redis favorite table selection change action, index: \(index)")
            let redisModel = state.tableState.datasource[index] as! RedisModel
            state.loginState.redisModel = redisModel
            return .none
        case .tableAction:
            logger.info("redis favorite table action \(state.tableState.selectIndex)")
            return .none
        case .loginAction:
            logger.info("redis favorite table action \(state.tableState.selectIndex)")
            return .none
        
        case .loadingAction:
            return .none
        }
    }
)
