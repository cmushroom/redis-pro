//
//  TableColumnType.swift
//  redis-pro
//
//  Created by chengpan on 2022/3/27.
//

import Foundation

protocol TableColumnTypeData:Equatable {
    var width:CGFloat { get }
}


enum TableColumnType: TableColumnTypeData {

    case DEFAULT
    case INDEX
    case IMAGE
    case KEY_TYPE
        
    //    case ID
    //    case DATE
    //    case DATETIME
    
    // 定义每个类型默认宽度
    var width: CGFloat {
        switch self {
        case .DEFAULT:
            return 100
        case .INDEX:
            return 20
        case .IMAGE:
            return 40
        case .KEY_TYPE:
            return 80
        }
    }
}
