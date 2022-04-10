//
//  TableColumnType.swift
//  redis-pro
//
//  Created by chengpan on 2022/3/27.
//

import Foundation

protocol TableColumnTypeData {
    var width:CGFloat { get }
}


enum TableColumnType: TableColumnTypeData {

    case DEFAULT
    case INDEX
    case IMAGE
        
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
        }
    }
}
