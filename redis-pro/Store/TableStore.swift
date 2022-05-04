//
//  TableStore.swift
//  redis-pro
//
//  Created by chengpan on 2022/4/30.
//

import Logging
import Foundation
import ComposableArchitecture

struct TableState: Equatable {
    var columns:[NTableColumn] = [NTableColumn]()
    var datasource: Array<AnyHashable> = [RedisModel()]
    var selectIndex:Int = -1
}

enum TableAction:Equatable {
    case onSelectionChange(Int)
    case onDouble(Int)
    case onDelete(Int)
    case refresh
}

struct TableEnvironment { }

let tableReducer = Reducer<TableState, TableAction, TableEnvironment> {
    state, action, _ in
    switch action {
    // 查询所有收藏
    case .refresh:
        return .none
    case let .onSelectionChange(index):
        print("table view on selection change action,  index: \(index)")
        state.selectIndex = index
        return .none
    case let .onDouble(index):
        print("table view on double click action, index: \(index)")
        state.datasource.append(RedisModel())
        return .none
    case let .onDelete(index):
        print("table view on delete action, index: \(index)")
        return .none
    }
}.debug()
