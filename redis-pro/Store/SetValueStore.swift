//
//  SetValueStore.swift
//  redis-pro
//
//  Created by chengpan on 2022/5/22.
//

import Logging
import Foundation
import SwiftyJSON
import ComposableArchitecture

private let logger = Logger(label: "set-value-store")


struct SetValueStore: ReducerProtocol {
    struct State: Equatable {
        @BindingState var editModalVisible:Bool = false
        @BindingState var editValue:String = ""
        // 1: LPUSH, 2: RPUSH
        var pushType:Int = 0
        var editIndex:Int = -1
        var isNew:Bool = false
        var redisKeyModel:RedisKeyModel?
        var pageState: PageStore.State = PageStore.State(showTotal: true)
        var tableState: TableStore.State = TableStore.State(
            columns: [.init(title: "Value", key: "self", width: 200)]
            , datasource: [], contextMenus: [.COPY, .EDIT, .DELETE]
            , selectIndex: -1)
        
        init() {
            logger.info("set value state init ...")
            pageState.showTotal = true
        }
    }

    enum Action:BindableAction, Equatable {
        
        case initial
        case refresh
        case search(String)
        case getValue
        case setValue(Page, [String?])
        
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
    
    var body: some ReducerProtocol<State, Action> {
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
                    let res = await redisInstanceModel.getClient().pageSet(key, page: page)
                    return .setValue(page, res)
                }
                .receive(on: mainQueue)
                .eraseToEffect()
                
            case let .setValue(page, datasource):
                state.tableState.datasource = datasource
                state.pageState.page = page
                return .none
             
            case .addNew:
                state.editValue = ""
                state.editIndex = -1
                
                state.isNew = true
                state.editModalVisible = true
                return .none
                
            case let .edit(index):
                // 编辑
                let item = state.tableState.datasource[index] as! String
                state.editIndex = index
                state.editValue = item
                state.isNew = false
                state.editModalVisible = true
                return .none
                
            case .submit:
                guard let redisKeyModel = state.redisKeyModel else {
                    return .none
                }

                let key = redisKeyModel.key
                let editValue = state.editValue
                let isNew = state.isNew
                let isNewKey = state.redisKeyModel?.isNew ?? false
                let originEle = isNew ? nil : state.tableState.datasource[state.editIndex] as? String
                return .task {
                    if isNew {
                        let _ = await redisInstanceModel.getClient().sadd(key, ele: editValue)
                    } else {
                        let _ = await redisInstanceModel.getClient().supdate(key, from: originEle!, to: editValue)
                    }
                    
                    return .submitSuccess(isNewKey)
                }
                .receive(on: mainQueue)
                .eraseToEffect()
            
            // 提交成功， 刷新列表
            case let .submitSuccess(isNewKey):
                let editValue = state.editValue
                // 修改，刷新单个值
                if state.isNew {
                    state.tableState.selectIndex = 0
                    state.tableState.datasource.insert(editValue, at: 0)
                    return .none
                }
                // 刷新列表
                else {
                    state.tableState.datasource[state.editIndex] = editValue
                    return .none
                }
             
                
            case let .deleteConfirm(index):
                guard index < state.tableState.datasource.count else {
                    return .none
                }
                
                let item = state.tableState.datasource[index] as! String
                return .future { callback in
                    Messages.confirm(String(format: NSLocalizedString("SET_DELETE_CONFIRM_TITLE", comment: ""), item)
                                      , message: String(format: NSLocalizedString("SET_DELETE_CONFIRM_MESSAGE", comment: ""), item)
                                      , primaryButton: "Delete"
                                      , action: {
                        callback(.success(.deleteKey(index)))
                    })
                }
                
            case let .deleteKey(index):
                
                let redisKeyModel = state.redisKeyModel!
                let item = state.tableState.datasource[index] as! String
                logger.info("delete set item, key: \(redisKeyModel.key), value: \(item)")
                
                return .task {
                    let r = await redisInstanceModel.getClient().srem(redisKeyModel.key, ele: item)
                    logger.info("do delete set item, key: \(redisKeyModel.key), value: \(item), r:\(r)")
                    
                    return r > 0 ? .deleteSuccess(index) : .none
                }
                .receive(on: mainQueue)
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
                guard let item = state.tableState.datasource[index] as? String else {
                    return .none
                }
                
                PasteboardHelper.copy(item)
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
    }
}
