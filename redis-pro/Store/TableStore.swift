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


struct TableStore: Reducer {
    struct State: Equatable {
        var columns: [NTableColumn] = []
        var datasource: Array<AnyHashable> = []
        var contextMenus: [TableContextMenu] = []
        // 一定要设置-1, 其它值会在view 刷新时， 陷入无限循环
        var selectIndex: Int = -1
        var selectIndexes: [Int] = []
        var defaultSelectIndex: Int = -1
        var dragable: Bool = false
        var multiSelect: Bool = false
        
        
//        是否空
        var isEmpty:Bool {
            datasource.isEmpty
        }
        var isSelect:Bool {
            selectIndex > -1
        }
    }

    enum Action:Equatable {
        case setDatasource([AnyHashable])
        case setSelectIndex(Int)
        case selectionChange(Int, [Int])
        case double(Int)
        case delete(Int)
        case copy(Int)
        case contextMenu(String, Int)
        case refresh
        case reset
        case dragComplete(Int, Int)
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .setDatasource(datasource):
                state.datasource = datasource
                state.selectIndex = min(state.selectIndex, state.datasource.count - 1)
                return .none
            
            case let .setSelectIndex(selectIndex):
                state.selectIndex = min(selectIndex, state.datasource.count - 1)
                return .none
                
            case .refresh:
                return .none
                
            case let .selectionChange(index, indexes):
                logger.info("table view on selection change action,  index: \(index)")
                state.selectIndex = index
                state.selectIndexes = indexes
                return .none
                
            case let .double(index):
                logger.info("table view on double click action, index: \(index)")
                return .none
                
            case let .delete(index):
                logger.info("table view on delete action, index: \(index)")
                return .none
                
            case let .copy(index):
                logger.info("table view on copy action, index: \(index)")
                return .none
                
            case let .contextMenu(sender, index):
                logger.info("table view on context menu action, sender: \(sender), index: \(index)")
                return .none
                
            case .reset:
                state.selectIndex = -1
                state.datasource = []
                return .none
            
            case let .dragComplete(from, to):
                
                let f = state.datasource[from]
                // 先删除原有的
                state.datasource.remove(at: from)
                
                if from > to {
                    state.datasource.insert(f, at: to)
                    state.selectIndex = to
                } else {
                    state.datasource.insert(f, at: to - 1)
                    state.selectIndex = to - 1
                }
                
                return .none
            }
        }
    }
}
