//
//  PageStore.swift
//  redis-pro
//
//  Created by chengpanwang on 2022/5/6.
//

import Logging
import Foundation
import ComposableArchitecture

private let logger = Logger(label: "page-store")

struct PageState: Equatable {
    var showTotal: Bool = false
    var current:Int = 1
    var size:Int = 50
    var total:Int = 0
    var keywords:String = ""
    
    var totalPage:Int {
        get {
            return total < 1 ? 1 : (total % size == 0 ? total / size : total / size + 1)
        }
    }
    var hasPrev:Bool {
        totalPage > 1 && current > 1
    }
    var hasNext:Bool {
        totalPage > 1 && current < totalPage
    }
    
    var page:Page {
        get {
            let page = Page()
            page.current = current
            page.size = size
            page.total = total
            page.keywords = keywords
            
            return page
        }
        set(page) {
            current = page.current
            size = page.size
            total = page.total
        }
    }

    init() {
        logger.info("page state init ...")
    }
    init(showTotal:Bool) {
        logger.info("page state init ...")
        self.showTotal = showTotal
    }
}


enum PageAction:BindableAction, Equatable {
    case initial
    case updateSize(Int)
    case nextPage
    case prevPage
    case none
    case binding(BindingAction<PageState>)
}

struct PageEnvironment {
}

let pageReducer = Reducer<PageState, PageAction, PageEnvironment>.combine(
    Reducer<PageState, PageAction, PageEnvironment> {
        state, action, env in
        switch action {
        // 初始化已设置的值
        case .initial:
            logger.info("page store initial...")
            return .none

        case let .updateSize(size):
            state.current = 1
            state.size = size
            return .none
        case .nextPage:
            state.current = state.current + 1
            return .none
        case .prevPage:
            state.current -= 1
            if state.current <= 1 {
                state.current = 1
            }
            return .none
        case .none:
            return .none
        case .binding:
            return .none
        }
    }
).binding().debug()
