//
//  HashValueStore.swift
//  redis-pro
//
//  Created by chengpan on 2022/5/14.
//


import Logging
import Foundation
import SwiftyJSON
import ComposableArchitecture

private let logger = Logger(label: "hash-value-store")
struct HashValueState: Equatable {
    @BindableState var editModalVisible:Bool = false
    @BindableState var field:String = ""
    @BindableState var value:String = ""
    var editIndex:Int = -1
    var isNew:Bool = false
    var redisKeyModel:RedisKeyModel?
    var pageState: PageState = PageState()
    var tableState: TableState = TableState(columns: [.init(title: "Field", key: "field", width: 100), .init(title: "Value", key: "value", width: 200)]
                                            , datasource: [], contextMenus: ["Edit", "Delete"], selectIndex: -1)
    
    init() {
        logger.info("hash value state init ...")
        pageState.showTotal = true
    }
}

enum HashValueAction:BindableAction, Equatable {
    case initial
    case refresh
    case search(String)
    case getValue
    case setValue(Page, [RedisHashEntryModel])
    
    case addNew
    case edit(Int)
    case submit
    case submitSuccess(Bool)
    
    case deleteConfirm(Int)
    case deleteKey(Int)
    case deleteSuccess(Int)
    
    case none
    case pageAction(PageAction)
    case tableAction(TableAction)
    case binding(BindingAction<HashValueState>)
}

struct HashValueEnvironment {
    var redisInstanceModel:RedisInstanceModel
    var mainQueue: AnySchedulerOf<DispatchQueue> = .main
}

let hashValueReducer = Reducer<HashValueState, HashValueAction, HashValueEnvironment>.combine(
    tableReducer.pullback(
        state: \.tableState,
        action: /HashValueAction.tableAction,
        environment: { env in .init() }
    ),
    pageReducer.pullback(
        state: \.pageState,
        action: /HashValueAction.pageAction,
        environment: { env in .init() }
    ),
    Reducer<HashValueState, HashValueAction, HashValueEnvironment> {
        state, action, env in
        switch action {
        // 初始化已设置的值
        case .initial:
            state.pageState.keywords = ""
            state.pageState.current = 1
            
            logger.info("value store initial...")
            return .result {
                .success(.getValue)
            }
            
        case .refresh:
            logger.info("value store initial...")
            return .result {
                .success(.getValue)
            }
            
        case let .search(keywords):
            state.pageState.current = 1
            state.pageState.keywords = keywords
            return .result {
                .success(.getValue)
            }
            
        case .getValue:
            guard let redisKeyModel = state.redisKeyModel else {
                return .none
            }
            // 清空
            if redisKeyModel.isNew {
                return .result {
                    .success(.tableAction(.reset))
                }
            }
            
            let key = redisKeyModel.key
            let page = state.pageState.page
            return .task {
                let res = await env.redisInstanceModel.getClient().pageHash(key, page: page)
                return .setValue(page, res)
            }
            .receive(on: env.mainQueue)
            .eraseToEffect()
            
        case let .setValue(page, datasource):
            state.tableState.datasource = datasource
            state.pageState.page = page
            return .none
         
        case .addNew:
            state.field = ""
            state.value = ""
            state.isNew = true
            state.editModalVisible = true
            return .none
            
        case let .edit(index):
            let item = state.tableState.datasource[index] as! RedisHashEntryModel
            state.editIndex = index
            state.field = item.field
            state.value = item.value
            state.isNew = false
            state.editModalVisible = true
            return .none
            
        case .submit:
            guard let redisKeyModel = state.redisKeyModel else {
                return .none
            }

            let key = redisKeyModel.key
            let field = state.field
            let value = state.value
            let isNewKey = state.redisKeyModel?.isNew ?? false
            return .task {
                let r = await env.redisInstanceModel.getClient().hset(key, field: field, value: value)
                return .submitSuccess(isNewKey)
            }
            .receive(on: env.mainQueue)
            .eraseToEffect()
         
        case let .submitSuccess(isNewKey):
            let item = RedisHashEntryModel(field: state.field, value: state.value)
            if state.isNew {
                state.tableState.selectIndex = 0
                state.tableState.datasource.insert(item, at: 0)
                state.isNew = false
            } else {
                state.tableState.datasource[state.editIndex] = item
            }
            return .none
         
            
        case let .deleteConfirm(index):
            guard index < state.tableState.datasource.count else {
                return .none
            }
            
            let item = state.tableState.datasource[index] as! RedisHashEntryModel
            return .future { callback in
                Messages.confirm(String(format: NSLocalizedString("HASH_DELETE_CONFIRM_TITLE'%@'", comment: ""), item.field)
                                  , message: String(format: NSLocalizedString("HASH_DELETE_CONFIRM_MESSAGE'%@'", comment: ""), item.field)
                                  , primaryButton: "Delete"
                                  , action: {
                    callback(.success(.deleteKey(index)))
                })
            }
            
        case let .deleteKey(index):
            
            let redisKeyModel = state.redisKeyModel!
            let item = state.tableState.datasource[index] as! RedisHashEntryModel
            logger.info("delete hash field, key: \(redisKeyModel.key), field: \(item.field)")
            
            return .task {
                let r = await env.redisInstanceModel.getClient().hdel(redisKeyModel.key, field: item.field)
                logger.info("do delete hash field, key: \(redisKeyModel.key), field: \(item.field), r:\(r)")
                
                return r > 0 ? .deleteSuccess(index) : .none
            }
            .receive(on: env.mainQueue)
            .eraseToEffect()
            
        case let .deleteSuccess(index):
            state.tableState.datasource.remove(at: index)
            
            return .result {
                .success(.refresh)
            }
            
        case .none:
            return .none
            
        // --------------------------- page action ---------------------------
        case .pageAction(.updateSize):
            return .result {
                .success(.getValue)
            }
        case .pageAction(.nextPage):
            return .result {
                .success(.getValue)
            }
        case .pageAction(.prevPage):
            return .result {
                .success(.getValue)
            }
        case .pageAction:
            return .none
        
            
        // delete key
        case let .tableAction(.contextMenu(title, index)):
            if title == "Delete" {
                return .result {
                    .success(.deleteConfirm(index))
                }
            }
            
            else  if title == "Edit" {
                return .result {
                    .success(.edit(index))
                }
            }
            
            return .none
            
        case let .tableAction(.double(index)):
            return .result {
                .success(.edit(index))
            }
            
        case let .tableAction(.delete(index)):
            return .result {
                .success(.deleteConfirm(index))
            }
        case .tableAction:
            return .none
        case .binding:
            return .none
        }
    }
).binding().debug()
