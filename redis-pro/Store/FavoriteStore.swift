//
//  Redis.swift
//  redis-pro
//
//  Created by chengpan on 2022/4/30.
//
import Logging
import Foundation
import ComposableArchitecture

private let logger = Logger(label: "favorite-store")

struct FavoriteStore: Reducer {
    
    struct State: Equatable {
        var tableState: TableStore.State = TableStore.State(columns: [NTableColumn(title: "FAVORITES", key: "name", width: 50, icon: .APP)], datasource: [], selectIndex: -1, dragable: true)
        var loginState: LoginStore.State = LoginStore.State()
    }

    enum Action:Equatable {
        case getAll
        case addNew
        case save(RedisModel)
        case deleteConfirm(Int)
        case delete(Int)
        case connect(Int)
        case connectSuccess(RedisModel)
        case initDefaultSelection
        case tableAction(TableStore.Action)
        case loginAction(LoginStore.Action)
        case loadingAction(LoadingStore.Action)
        case none
    }
    
    
    @Dependency(\.redisInstance) var redisInstanceModel: RedisInstanceModel
    @Dependency(\.redisClient) var redisClient: RediStackClient
    
    var body: some Reducer<State, Action> {
        Scope(state: \.tableState, action: /Action.tableAction) {
            TableStore()
        }
        Scope(state: \.loginState, action: /Action.loginAction) {
            LoginStore()
        }
        
        Reduce { state, action in
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
                return .run { send in
                    await send(.save(RedisModel()))
                }
            case let .save(redisModel):
                logger.info("save redis favorite: \(redisModel)")
                
                let index = RedisDefaults.save(redisModel)
                state.tableState.selectIndex = index
                return .run { send in
                    await send(.getAll)
                }
            case let .deleteConfirm(index):
                if state.tableState.datasource.count <= index {
                    return .none
                }
                
                let redisModel = state.tableState.datasource[index] as! RedisModel
                
                return .run { send in
                    let r = await Messages.confirmAsync(String(format: NSLocalizedString("CONFIRM_FAVORITE_REDIS_TITLE'%@'", comment: ""), redisModel.name)
                                      , message: String(format: NSLocalizedString("CONFIRM_FAVORITE_REDIS_MESSAGE'%@'", comment: ""), redisModel.name)
                                      , primaryButton: "Delete")
                    
                    return await send(r ? .delete(index) : .none)
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
                
                return .run { send in
                    let r = await redisInstanceModel.connect(redisModel)
                    redisClient.redisModel = redisModel
                    let _ = await redisClient.initConnection()
                    
                    logger.info("on connect to redis server: \(redisModel) , result: \(r)")
                    RedisDefaults.saveLastUse(redisModel)
                    if r {
                        await send(.connectSuccess(redisModel))
                    }
                }

            case let .tableAction(.copy(index)):
                let redisModel = state.tableState.datasource[index] as! RedisModel
                PasteboardHelper.copy(redisModel.name)
                return .none
            
            case let .tableAction(.dragComplete(from, to)):
                let _ = RedisDefaults.save(state.tableState.datasource as! [RedisModel])
                return .none
                
            case let .tableAction(.double(index)):
                return .run { send in
                    await send(.connect(index))
                }
            case let .tableAction(.selectionChange(index, _)):
                guard index > -1 else { return .none }
                
                logger.info("redis favorite table selection change action, index: \(index)")
                let redisModel = state.tableState.datasource[index] as! RedisModel
                state.loginState.redisModel = redisModel
                return .none
            case let .tableAction(.delete(index)):
                return .run { send in
                    await send(.deleteConfirm(index))
                }
            case .tableAction:
                logger.info("redis favorite table action \(state.tableState.selectIndex)")
                return .none
                
            case .loginAction(.connect):
                let index = state.tableState.selectIndex
                return .run { send in
                    await send(.connect(index))
                }
            case .loginAction(.save):
                let redisModel = state.loginState.redisModel
                return .run { send in
                    await send(.save(redisModel))
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
    }
}
