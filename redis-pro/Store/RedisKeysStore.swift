//
//  RedisKeysStore.swift
//  redis-pro
//
//  Created by chengpanwang on 2022/5/6.
//

import Logging
import Foundation
import SwiftUI
import ComposableArchitecture

private let logger = Logger(label: "redisKeys-store")

struct RedisKeysState: Equatable {
    var database:Int = 0
    var dbsize:Int = 0
    var keywords:String = ""
    
    var mainViewType: MainViewTypeEnum = .EDITOR
    var tableState: TableState = TableState(columns: [.init(type: .KEY_TYPE,title: "Type", key: "type", width: 40), .init(title: "Key", key: "key", width: 50)]
                                            , datasource: [], contextMenus: ["Rename", "Delete"], selectIndex: -1)
    var redisSystemState:RedisSystemState = RedisSystemState()
    var valueState: ValueState = ValueState()
    var databaseState: DatabaseState = DatabaseState()
    var pageState: PageState = PageState()
    var renameState: RenameState = RenameState()
    
    init() {
        logger.info("redisKeys state init ...")
    }
}


enum RedisKeysAction:Equatable {
    case initial
    case dbsize
    case refresh
    case refreshCount
    case search(String)
    case getKeys
    case setKeys(Page, [RedisKeyModel])
    case setMainViewType(MainViewTypeEnum)
    case addNew
    
    case deleteConfirm(Int)
    case deleteKey(Int)
    case deleteSuccess(Int)
    
    case onKeyChange(Int)
    case updateDBSize(Int)
    case flushDBConfirm
    case flushDB
    case tableAction(TableAction)
    case redisSystemAction(RedisSystemAction)
    case valueAction(ValueAction)
    case databaseAction(DatabaseAction)
    case pageAction(PageAction)
    case renameAction(RenameAction)
    case none
}

struct RedisKeysEnvironment {
    var redisInstanceModel:RedisInstanceModel
    var mainQueue: AnySchedulerOf<DispatchQueue> = .main
}

let redisKeysReducer = Reducer<RedisKeysState, RedisKeysAction, RedisKeysEnvironment>.combine(
    tableReducer.pullback(
        state: \.tableState,
        action: /RedisKeysAction.tableAction,
        environment: { env in .init() }
    ),
    redisSystemReducer.pullback(
        state: \.redisSystemState,
        action: /RedisKeysAction.redisSystemAction,
        environment: { env in .live(environment: RedisSystemEnvironment(redisInstanceModel: env.redisInstanceModel)) }
    ),
    valueReducer.pullback(
        state: \.valueState,
        action: /RedisKeysAction.valueAction,
        environment: { env in .init(redisInstanceModel: env.redisInstanceModel) }
    ),
    databaseReducer.pullback(
        state: \.databaseState,
        action: /RedisKeysAction.databaseAction,
        environment: { env in .init(redisInstanceModel: env.redisInstanceModel) }
    ),
    pageReducer.pullback(
        state: \.pageState,
        action: /RedisKeysAction.pageAction,
        environment: { _ in .init() }
    ),
    renameReducer.pullback(
        state: \.renameState,
        action: /RedisKeysAction.renameAction,
        environment: { env in .init(redisInstanceModel: env.redisInstanceModel) }
    ),
    Reducer<RedisKeysState, RedisKeysAction, RedisKeysEnvironment> {
        state, action, env in
        switch action {
            // 初始化已设置的值
        case .initial:
            logger.info("redis keys store initial...")
            state.pageState.current = 1
            state.pageState.total = 0
            
            return Effect<RedisKeysAction, Never>.merge(
                .result {
                    .success(.getKeys)
                }
                , .result {
                    .success(.dbsize)
                }
            )
        
        // 只刷新数量，比如删除时不刷新列表数据， 只刷新数量
        case .refreshCount:
            return .result {
                .success(.dbsize)
            }
            
        // 全部刷新
        case .refresh:
            return .result {
                .success(.initial)
            }
            
        case let .search(keywords):
            state.pageState.current = 1
            state.pageState.keywords = keywords
            return .result {
                .success(.getKeys)
            }
            
            
        case .dbsize:
            return .task {
                let r = await env.redisInstanceModel.getClient().dbsize()
                return .updateDBSize(r)
            }
            .receive(on: env.mainQueue)
            .eraseToEffect()
        // 分页查询 key
        case .getKeys:
            
            let page = state.pageState.page
            return .task {
                let keysPage = await env.redisInstanceModel.getClient().pageKeys(page)
                return .setKeys(page, keysPage)
            }
            .receive(on: env.mainQueue)
            .eraseToEffect()
        case let .setKeys(page, redisKeys):
            state.tableState.datasource = redisKeys
            state.pageState.total = page.total
            
            if !redisKeys.isEmpty {
                state.tableState.selectIndex = 0
            }
            return .none
        case let .setMainViewType(mainViewType):
            state.mainViewType = mainViewType
            return .none
        case let .updateDBSize(dbsize):
            state.dbsize = dbsize
            return .none
        
        case .addNew:
            let newKey = RedisKeyModel()
            newKey.initNew()
            return .result{
                .success(.valueAction(.keyChange(newKey)))
            }
            
        case let .deleteConfirm(index):
            let redisKeyModel = state.tableState.datasource[index] as! RedisKeyModel
            return Effect<RedisKeysAction, Never>.future { callback in
                Messages.confirm(String(format: NSLocalizedString("REDIS_KEY_DELETE_CONFIRM_TITLE'%@'", comment: ""), redisKeyModel.key)
                                  , message: String(format: NSLocalizedString("REDIS_KEY_DELETE_CONFIRM_MESSAGE'%@'", comment: ""), redisKeyModel.key)
                                  , primaryButton: "Delete"
                                  , action: {
                    callback(.success(.deleteKey(index)))
                })
            }
            
        case let .deleteKey(index):
            let redisKeyModel = state.tableState.datasource[index] as! RedisKeyModel
            logger.info("delete key: \(redisKeyModel.key)")
            
            return .task {
                let r = await env.redisInstanceModel.getClient().del(redisKeyModel.key)
                logger.info("on delete redis key: \(index), r:\(r)")
                
                return r > 0 ? .deleteSuccess(index) : .none
            }
            .receive(on: env.mainQueue)
            .eraseToEffect()
            
        case let .deleteSuccess(index):
            state.tableState.datasource.remove(at: index)
            
            return .result {
                .success(.refreshCount)
            }
            
        case let .onKeyChange(index):
            guard index > -1 else { return .none }
            
            state.mainViewType = .EDITOR
            let redisKeyModel = state.tableState.datasource[index] as! RedisKeyModel
            return .result{
                .success(.valueAction(.keyChange(redisKeyModel)))
            }
            
        case .flushDBConfirm:
            return Effect<RedisKeysAction, Never>.future { callback in
                Messages.confirm("Flush DB ?"
                                  , message: "Are you sure you want to flush db? This operation cannot be undone."
                                  , primaryButton: "Ok"
                                  , action: {
                    callback(.success(.flushDB))
                }
                )
            }
        case .flushDB:
            return .task {
                let r = await env.redisInstanceModel.getClient().flushDB()
                if r {
                    return .initial
                }
                return .none
            }
            .receive(on: env.mainQueue)
            .eraseToEffect()
        
        // redis 系统信息
            
        case .redisSystemAction(.setSystemView):
            state.mainViewType = .SYSTEM
            return .none
        case .redisSystemAction:
            return .none
            
        // submit 成功后， 如果是新增key，添加到列表
        case let .valueAction(.submitSuccess(isNew)):
            let redisKeyModel = state.valueState.keyState.redisKeyModel
            
            if isNew {
                // 此处直接设置 selectIndex， 不会触 selectionChange, 会在设置datasource 时一起设置
                state.tableState.selectIndex = 0
                state.tableState.datasource.insert(redisKeyModel, at: 0)
            }
            return .none
            
        case .valueAction:
            return .none
            
        // --------------------------- table action ---------------------------
        case let .tableAction(.selectionChange(index)):
            return .result {
                .success(.onKeyChange(index))
            }
        
        // delete key
        case let .tableAction(.contextMenu(title, index)):
            if title == "Delete" {
                
                return .result {
                    .success(.deleteConfirm(index))
                }
            }
            
            else  if title == "Rename" {
                let redisKeyModel = state.tableState.datasource[state.tableState.selectIndex] as! RedisKeyModel
                state.renameState.key = redisKeyModel.key
                state.renameState.newKey = redisKeyModel.key
                state.renameState.index = state.tableState.selectIndex
                state.renameState.visible = true
        
            }
            return .none
            
        case let .tableAction(.double(index)):
            let redisKeyModel = state.tableState.datasource[state.tableState.selectIndex] as! RedisKeyModel
            state.renameState.key = redisKeyModel.key
            state.renameState.newKey = redisKeyModel.key
            state.renameState.index = state.tableState.selectIndex
            state.renameState.visible = true
            
            return .none
            
        case let .tableAction(.delete(index)):
            return .result {
                .success(.deleteConfirm(index))
            }
            
        case .tableAction:
            return .none
        
        // --------------------------- database action ---------------------------
        case let .databaseAction(.change(database)):
            logger.info("change database, \(database)")
            return .task {
                let r = await env.redisInstanceModel.getClient().selectDB(database)
                if r {
                    return .initial
                }
                return .none
            }
            .receive(on: env.mainQueue)
            .eraseToEffect()
        case .databaseAction:
            return .none
            
        // --------------------------- page action ---------------------------
        case .pageAction(.updateSize):
            return .result {
                .success(.getKeys)
            }
        case .pageAction(.nextPage):
            return .result {
                .success(.getKeys)
            }
        case .pageAction(.prevPage):
            return .result {
                .success(.getKeys)
            }
        case .pageAction:
            return .none
        
        case let .renameAction(.setKey(index, newKey)):
            var datasource:[RedisKeyModel] = state.tableState.datasource as! [RedisKeyModel]
            let old = datasource[index]
            datasource[index] = RedisKeyModel(newKey, type: old.type)
            state.tableState.datasource = datasource
            return .none
            
        case .renameAction:
            return .none
            
        case .none:
            return .none
        }
    }
).debug()

