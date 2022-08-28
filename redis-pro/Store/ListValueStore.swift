//
//  ListValueStore.swift
//  redis-pro
//
//  Created by chengpan on 2022/5/22.
//

import Logging
import Foundation
import SwiftyJSON
import ComposableArchitecture

private let logger = Logger(label: "list-value-store")
struct ListValueState: Equatable {
    @BindableState var editModalVisible:Bool = false
    @BindableState var editValue:String = ""
    // 1: LPUSH, 2: RPUSH
    var pushType:Int = 0
    var editIndex:Int = -1
    var isNew:Bool = false
    var redisKeyModel:RedisKeyModel?
    var pageState: PageState = PageState(showTotal: true)
    var tableState: TableState = TableState(
        columns: [.init(title: "Index", key: "index", width: 100), .init(title: "Value", key: "value", width: 200)]
        , datasource: [], contextMenus: [.COPY, .EDIT, .DELETE]
        , selectIndex: -1)
    
    init() {
        logger.info("list value state init ...")
        pageState.showTotal = true
    }
}

enum ListValueAction:BindableAction, Equatable {
    
    case initial
    case refresh
    case search(String)
    case getValue
    case setValue(Page, [RedisListItemModel])
    
    case addNew(Int)
    case edit(Int)
    case submit
    case submitSuccess(Bool)
    
    case deleteConfirm(Int)
    case deleteKey(Int)
    case deleteSuccess(Int)
    
    case none
    case pageAction(PageAction)
    case tableAction(TableAction)
    case binding(BindingAction<ListValueState>)
}

struct ListValueEnvironment {
    var redisInstanceModel:RedisInstanceModel
    var mainQueue: AnySchedulerOf<DispatchQueue> = .main
}

let listValueReducer = Reducer<ListValueState, ListValueAction, ListValueEnvironment>.combine(
    tableReducer.pullback(
        state: \.tableState,
        action: /ListValueAction.tableAction,
        environment: { env in .init() }
    ),
    pageReducer.pullback(
        state: \.pageState,
        action: /ListValueAction.pageAction,
        environment: { env in .init() }
    ),
    Reducer<ListValueState, ListValueAction, ListValueEnvironment> {
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
                let res = await env.redisInstanceModel.getClient().pageList(key, page: page)
                return .setValue(page, res)
            }
            .receive(on: env.mainQueue)
            .eraseToEffect()
            
        case let .setValue(page, datasource):
            state.tableState.datasource = datasource
            state.pageState.page = page
            return .none
         
        case let .addNew(type):
            state.editValue = ""
            state.editIndex = -1
            
            state.isNew = true
            state.pushType = type
            state.editModalVisible = true
            return .none
            
        case let .edit(index):
            // 编辑
            state.pushType = 0
            let item = state.tableState.datasource[index] as! RedisListItemModel
            state.editIndex = index
            state.editValue = item.value
            state.isNew = false
            state.editModalVisible = true
            return .none
            
        case .submit:
            guard let redisKeyModel = state.redisKeyModel else {
                return .none
            }

            let key = redisKeyModel.key
            let editValue = state.editValue
            let isNewKey = state.redisKeyModel?.isNew ?? false
            let pushType = state.pushType
            let item = pushType == 0 ? state.tableState.datasource[state.editIndex] as? RedisListItemModel : nil
            return .task {
                if pushType == -1 {
                    let _ = await env.redisInstanceModel.getClient().lpush(key, value: editValue)
                } else if pushType == -2 {
                    let _ = await env.redisInstanceModel.getClient().rpush(key, value: editValue)
                } else if pushType == 0 {
                    let _ = await env.redisInstanceModel.getClient().lset(key, index: item!.index, value: editValue)
                    logger.info("redis list set success, update list")
                } else {
                    Messages.show("System error!!!")
                    return .none
                }
                
                return .submitSuccess(isNewKey)
            }
            .receive(on: env.mainQueue)
            .eraseToEffect()
        
        // 提交成功， 刷新列表
        case let .submitSuccess(isNewKey):
            if state.isNew {
                state.isNew = false
            }
            let pushType = state.pushType
            // 修改，刷新单个值
            if pushType == 0 {
                let item = state.tableState.datasource[state.editIndex] as! RedisListItemModel
                let newItem = RedisListItemModel(item.index, state.editValue)
                state.tableState.datasource[state.editIndex] = newItem
                return .none
            }
            // 刷新列表
            else {
                return .result {
                    .success(.refresh)
                }
            }
         
            
        case let .deleteConfirm(index):
            guard index < state.tableState.datasource.count else {
                return .none
            }
            
            let item = state.tableState.datasource[index] as! RedisListItemModel
            return .future { callback in
                Messages.confirm(String(format: NSLocalizedString("LIST_DELETE_CONFIRM_TITLE'%@'", comment: ""), item.value)
                                  , message: String(format: NSLocalizedString("LIST_DELETE_CONFIRM_MESSAGE", comment: ""), item.index, item.value)
                                  , primaryButton: "Delete"
                                  , action: {
                    callback(.success(.deleteKey(index)))
                })
            }
            
        case let .deleteKey(index):
            
            let redisKeyModel = state.redisKeyModel!
            let item = state.tableState.datasource[index] as! RedisListItemModel
            logger.info("delete list item, key: \(redisKeyModel.key), index: \(item.index), value: \(item.value)")
            
            return .task {
                let r = await env.redisInstanceModel.getClient().ldel(redisKeyModel.key, index: item.index, value: item.value)
                logger.info("do delete list item, key: \(redisKeyModel.key), value: \(item.value), r:\(r)")
                
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
            
        // MARK: - page action
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
        
        // MARK: - table action
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
            
        case let .tableAction(.copy(index)):
            let item = state.tableState.datasource[index] as! RedisListItemModel
            PasteboardHelper.copy(item.value)
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
