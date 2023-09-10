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

struct PageStore: Reducer {
    struct State: Equatable {
        var showTotal: Bool = false
        var current:Int = 1
        @BindingState var size:Int = 50
        var total:Int = 0
        var keywords:String = ""
        var fastPage = true
        var fastPageMax = 99
        
        /// 总页数
        var totalPage:Int {
            get {
                return total < 1 ? 1 : (total % size == 0 ? total / size : total / size + 1)
            }
        }
        
        var totalPageText: String {
            get {
                if fastPage {
                    return totalPage > fastPageMax ? "\(fastPageMax)+" : "\(totalPage)"
                }
                return "\(totalPage)"
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
    }
    
    
    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case initial
        case updateSize(Int)
        case nextPage
        case prevPage
        case none
    }
    
    
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
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
    }
}
