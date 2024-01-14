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


struct HashValueStore: Reducer {
    
    struct State: Equatable {
        @BindingState var editModalVisible:Bool = false
        @BindingState var field:String = ""
        @BindingState var value:String = ""
        var editIndex:Int = -1
        var isNew:Bool = false
        var redisKeyModel:RedisKeyModel?
        var pageState: PageStore.State = PageStore.State(showTotal: true)
        var tableState: TableStore.State = TableStore.State(
            columns: [.init(title: "Field", key: "field", width: 100), .init(title: "Value", key: "value", width: 200)]
            , datasource: []
            , contextMenus: [.EDIT, .DELETE, .COPY, .COPY_FIELD, .COPY_VALUE]
            , selectIndex: -1)
        
    }
    
    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
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
        case pageAction(PageStore.Action)
        case tableAction(TableStore.Action)
    }
    
    @Dependency(\.redisInstance) var redisInstanceModel:RedisInstanceModel
    let mainQueue: AnySchedulerOf<DispatchQueue> = .main
    
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
            case .binding:
                return .none
            
                // 初始化已设置的值
            case .initial:
                state.pageState.keywords = ""
                state.pageState.current = 1
                
                logger.info("value store initial...")
                return .run  { send in
                    await send(.getValue)
                }
                
            case .refresh:
                logger.info("value store initial...")
                return .run  { send in
                    await send(.getValue)
                }
                
            case let .search(keywords):
                state.pageState.current = 1
                state.pageState.keywords = keywords
                return .run  { send in
                    await send(.getValue)
                }
                
            case .getValue:
                guard let redisKeyModel = state.redisKeyModel else {
                    return .none
                }
                // 清空
                if redisKeyModel.isNew {
                    return .run  { send in
                        await send(.tableAction(.reset))
                    }
                }
                
                let key = redisKeyModel.key
                let page = state.pageState.page
                return .run {  send in
                    let res = await redisInstanceModel.getClient().pageHash(key, page: page)
                    await  send(.setValue(page, res))
                }
                
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
                return .run { send in
                    let r = await redisInstanceModel.getClient().hset(key, field: field, value: value)
                    await send(.submitSuccess(isNewKey))
                }
                
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
                return .run { send in
                    let r = await Messages.confirmAsync(String(format: NSLocalizedString("HASH_DELETE_CONFIRM_TITLE'%@'", comment: ""), item.field)
                                     , message: String(format: NSLocalizedString("HASH_DELETE_CONFIRM_MESSAGE'%@'", comment: ""), item.field)
                                     , primaryButton: "Delete")
                    
                    await send(r ? .deleteKey(index) : .none)
                }
                
            case let .deleteKey(index):
                
                let redisKeyModel = state.redisKeyModel!
                let item = state.tableState.datasource[index] as! RedisHashEntryModel
                logger.info("delete hash field, key: \(redisKeyModel.key), field: \(item.field)")
                
                return .run { send in
                    let r = await redisInstanceModel.getClient().hdel(redisKeyModel.key, field: item.field)
                    logger.info("do delete hash field, key: \(redisKeyModel.key), field: \(item.field), r:\(r)")
                    
                    if r > 0 {
                        await send(.deleteSuccess(index))
                    }
                }
                
            case let .deleteSuccess(index):
                state.tableState.datasource.remove(at: index)
                
                return .run  { send in
                    await send(.refresh)
                }
                
            case .none:
                return .none
                
                //MARK: -Page action
            case .pageAction(.updateSize):
                return .run  { send in
                    await send(.getValue)
                }
            case .pageAction(.nextPage):
                return .run  { send in
                    await send(.getValue)
                }
            case .pageAction(.prevPage):
                return .run  { send in
                    await send(.getValue)
                }
            case .pageAction:
                return .none
                
                
                //MARK: - table action
                // context menu
            case let .tableAction(.contextMenu(title, index)):
                if title == "Delete" {
                    return .run  { send in
                        await send(.deleteConfirm(index))
                    }
                }
                
                else  if title == "Edit" {
                    return .run  { send in
                        await send(.edit(index))
                    }
                }
                
                else  if title == TableContextMenu.COPY_FIELD.rawValue {
                    let item = state.tableState.datasource[index] as! RedisHashEntryModel
                    PasteboardHelper.copy(item.field)
                }
                else  if title == TableContextMenu.COPY_VALUE.rawValue {
                    let item = state.tableState.datasource[index] as! RedisHashEntryModel
                    PasteboardHelper.copy(item.value)
                }
                return .none
                
            case let .tableAction(.copy(index)):
                let item = state.tableState.datasource[index] as! RedisHashEntryModel
                PasteboardHelper.copy("Field: \(item.field) \n Value: \(item.value)")
                return .none
                
            case let .tableAction(.double(index)):
                return .run  { send in
                    await send(.edit(index))
                }
                
            case let .tableAction(.delete(index)):
                return .run  { send in
                    await send(.deleteConfirm(index))
                }
            case .tableAction:
                return .none
            }
        }
        
    }
}
