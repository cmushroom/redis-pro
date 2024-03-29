//
//  ZSetValueStore.swift
//  redis-pro
//
//  Created by chengpan on 2022/5/28.
//

import Logging
import Foundation
import SwiftyJSON
import ComposableArchitecture

private let logger = Logger(label: "zset-value-store")

struct ZSetValueStore: Reducer {
    
    // MARK: - state
    struct State: Equatable {
        @BindingState var editModalVisible:Bool = false
        @BindingState var editValue:String = ""
        @BindingState var editScore:Double = 0
        
        var editIndex:Int = -1
        var isNew:Bool = false
        var redisKeyModel:RedisKeyModel?
        var pageState: PageStore.State = PageStore.State(showTotal: true)
        var tableState: TableStore.State = TableStore.State(
            columns: [.init(title: "Score", key: "score", width: 80), .init(title: "Value", key: "value", width: 200)]
            , datasource: [], contextMenus: [.COPY, .EDIT, .DELETE]
            , selectIndex: -1)
        
        init() {
            logger.info("zset value state init ...")
            pageState.showTotal = true
        }
    }

    // MARK: - action
    enum Action:BindableAction, Equatable {
        
        case initial
        case refresh
        case search(String)
        case getValue
        case setValue(Page, [RedisZSetItemModel])
        
        case addNew
        case edit(Int)
        case submit
        case submitSuccess(Bool)
        
        case deleteConfirm(Int)
        case deleteKey(Int)
        case deleteSuccess(Int)
        
        case none
        case pageAction(PageStore.Action)
        case tableAction(TableStore.Action)
        case binding(BindingAction<State>)
    }
    
    
    @Dependency(\.redisInstance) var redisInstanceModel:RedisInstanceModel
    var mainQueue: AnySchedulerOf<DispatchQueue> = .main

    
    var body: some Reducer<State, Action> {
        BindingReducer()
        Scope(state: \.tableState, action: /Action.tableAction) {
            TableStore()
        }
        Scope(state: \.pageState, action: /Action.pageAction) {
            PageStore()
        }
        Reduce { state, action in
            switch action {
            // 初始化已设置的值
            case .initial:
                state.pageState.keywords = ""
                state.pageState.current = 1
                
                logger.info("value store initial...")
                return .run { send in
                    await send(.getValue)
                }
                
            case .refresh:
                logger.info("value store initial...")
                return .run { send in
                    await send(.getValue)
                }
                
            case let .search(keywords):
                state.pageState.current = 1
                state.pageState.keywords = keywords
                return .run { send in
                    await send(.getValue)
                }
                
            case .getValue:
                guard let redisKeyModel = state.redisKeyModel else {
                    return .none
                }
                // 清空
                if redisKeyModel.isNew {
                    return .run { send in
                        await send(.tableAction(.reset))
                    }
                }
                
                let key = redisKeyModel.key
                let page = state.pageState.page
                return .run { send in
                    let res = await redisInstanceModel.getClient().pageZSet(key, page: page)
                    await send(.setValue(page, res))
                }
                
            case let .setValue(page, datasource):
                state.tableState.datasource = datasource
                state.pageState.page = page
                return .none
             
            case .addNew:
                state.editValue = ""
                state.editScore = 0
                state.editIndex = -1
                
                state.isNew = true
                state.editModalVisible = true
                return .none
                
            case let .edit(index):
                // 编辑
                let item = state.tableState.datasource[index] as! RedisZSetItemModel
                state.editIndex = index
                state.editValue = item.value
                state.editScore = Double(item.score) ?? 0
                state.isNew = false
                state.editModalVisible = true
                return .none
                
            case .submit:
                guard let redisKeyModel = state.redisKeyModel else {
                    return .none
                }

                let key = redisKeyModel.key
                let editValue = state.editValue
                let editScore = state.editScore
                let isNew = state.isNew
                let isNewKey = state.redisKeyModel?.isNew ?? false
                let originEle = isNew ? nil : state.tableState.datasource[state.editIndex] as? RedisZSetItemModel
                return .run { send in
                    var r = false
                    if isNew {
                        r = await redisInstanceModel.getClient().zadd(key, score: editScore, ele: editValue)
                    } else {
                        r = await redisInstanceModel.getClient().zupdate(key, from: originEle!.value, to: editValue, score: editScore)
                    }
                    
                    return r ? await send(.submitSuccess(isNewKey)) : await send(.none)
                    
                }
            
            // 提交成功， 刷新列表
            case let .submitSuccess(isNewKey):
                let editValue = state.editValue
                let editScore = "\(state.editScore)"
                // 修改，刷新单个值
                if state.isNew {
                    state.tableState.selectIndex = 0
                    state.tableState.datasource.insert(RedisZSetItemModel(value: editValue, score: editScore), at: 0)
                    return .none
                }
                // 刷新列表
                else {
                    state.tableState.datasource[state.editIndex] = RedisZSetItemModel(value: editValue, score: editScore)
                    return .none
                }
             
                
            case let .deleteConfirm(index):
                guard index < state.tableState.datasource.count else {
                    return .none
                }
                
                let item = state.tableState.datasource[index] as! RedisZSetItemModel
                return .run { send in
                    let r = await Messages.confirmAsync(StringHelper.format("ZSET_DELETE_CONFIRM_TITLE", item.value)
                                      , message: StringHelper.format("ZSET_DELETE_CONFIRM_MESSAGE", item.value)
                                      , primaryButton: "Delete")
                    
                    await send(r ? .deleteKey(index) : .none)
                }
                
            case let .deleteKey(index):
                
                let redisKeyModel = state.redisKeyModel!
                let item = state.tableState.datasource[index] as! RedisZSetItemModel
                logger.info("delete zset item, key: \(redisKeyModel.key), value: \(item.value)")
                
                return .run { send in
                    let r = await redisInstanceModel.getClient().zrem(redisKeyModel.key, ele: item.value)
                    logger.info("do delete zset item, key: \(redisKeyModel.key), value: \(item), r:\(r)")
                    
                    if r > 0 {
                        await send(.deleteSuccess(index))
                    }
                }
                
            case let .deleteSuccess(index):
                state.tableState.datasource.remove(at: index)
                
                return .run { send in
                    await send(.refresh)
                }
                
            case .none:
                return .none
                
            // MARK: - page action
            case .pageAction(.updateSize):
                return .run { send in
                    await send(.getValue)
                }
            case .pageAction(.nextPage):
                return .run { send in
                    await send(.getValue)
                }
            case .pageAction(.prevPage):
                return .run { send in
                    await send(.getValue)
                }
            case .pageAction:
                return .none
            
            // MARK: - table action
            // delete key
            case let .tableAction(.contextMenu(title, index)):
                if title == "Delete" {
                    return .run { send in
                        await send(.deleteConfirm(index))
                    }
                }
                
                else  if title == "Edit" {
                    return .run { send in
                        await send(.edit(index))
                    }
                }
                
                return .none
                
            case let .tableAction(.copy(index)):
                let item = state.tableState.datasource[index] as! RedisZSetItemModel
                
                PasteboardHelper.copy("Score: \(item.score) \nValue: \(item.value)")
                return .none
                
            case let .tableAction(.double(index)):
                return .run { send in
                    await send(.edit(index))
                }
                
            case let .tableAction(.delete(index)):
                return .run { send in
                    await send(.deleteConfirm(index))
                }
            case .tableAction:
                return .none
            case .binding:
                return .none
            }
        }
    }
}
