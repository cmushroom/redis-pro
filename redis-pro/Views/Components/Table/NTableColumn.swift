//
//  NTableColumn.swift
//  redis-pro
//
//  Created by chengpan on 2022/3/27.
//

import Foundation
struct NTableColumn {
    var type:TableColumnType = .DEFAULT
    var title:String
    var key:String
    var width:CGFloat?
}
