//
//  ScanStore.swift
//  redis-pro
//
//  Created by chengpan on 2022/5/14.
//

import Logging
import Foundation
import ComposableArchitecture

private let logger = Logger(label: "scan-store")

struct ScanState: Equatable {
    var showTotal: Bool = false
    var current:Int = 1
    var size:Int = 50
    var total:Int = 0
    var keywords:String = ""
    
    var totalScan:Int {
        get {
            return total < 1 ? 1 : (total % size == 0 ? total / size : total / size + 1)
        }
    }
    var hasPrev:Bool {
        totalScan > 1 && current > 1
    }
    var hasNext:Bool {
        totalScan > 1 && current < totalScan
    }
    
    var scanModel:ScanModel {
        get {
            let scan = ScanModel()
            scan.current = current
            scan.size = size
            scan.total = total
            scan.keywords = keywords
            
            return scan
        }
        set(scan) {
            current = scan.current
            size = scan.size
            total = scan.total
        }
    }

    init() {
        logger.info("scan state init ...")
    }
}


enum ScanAction:BindableAction, Equatable {
    case initial
    case updateSize(Int)
    case nextScan
    case prevScan
    case none
    case binding(BindingAction<ScanState>)
}

struct ScanEnvironment {
}

let scanReducer = Reducer<ScanState, ScanAction, ScanEnvironment>.combine(
    Reducer<ScanState, ScanAction, ScanEnvironment> {
        state, action, env in
        switch action {
        // 初始化已设置的值
        case .initial:
            logger.info("scan store initial...")
            return .none

        case let .updateSize(size):
            state.current = 1
            state.size = size
            return .none
        case .nextScan:
            state.current = state.current + 1
            return .none
        case .prevScan:
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
