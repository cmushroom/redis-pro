//
//  TableStore.swift
//  redis-pro
//
//  Created by chengpan on 2022/4/30.
//

import Logging
import Foundation
import ComposableArchitecture
private let logger = Logger(label: "table-store")

struct TableState: Equatable {
    var columns:[NTableColumn] = []
    var datasource: Array<AnyHashable> = []
    var contextMenus: [String] = []
    // 一定要设置-1, 其它值会在view 刷新时， 陷入无限循环
    var selectIndex:Int = -1
    var defaultSelectIndex:Int = -1
}

enum TableAction:Equatable {
    case selectionChange(Int)
    case double(Int)
    case delete(Int)
    case contextMenu(String, Int)
    case refresh
    case reset
}

struct TableEnvironment { }

let tableReducer = Reducer<TableState, TableAction, TableEnvironment> {
    state, action, _ in
    switch action {
    // 查询所有收藏
    case .refresh:
        return .none
        
    case let .selectionChange(index):
        logger.info("table view on selection change action,  index: \(index)")
        state.selectIndex = index
        return .none
        
    case let .double(index):
        logger.info("table view on double click action, index: \(index)")
        return .none
        
    case let .delete(index):
        logger.info("table view on delete action, index: \(index)")
        return .none
    
    case let .contextMenu(sender, index):
        logger.info("table view on context menu action, sender: \(sender), index: \(index)")
        return .none
        
    case .reset:
        state.selectIndex = -1
        state.datasource = []
        return .none
    }
}.debug()
