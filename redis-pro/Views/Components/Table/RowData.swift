//
//  RowData.swift
//  redis-pro
//
//  Created by chengpan on 2022/4/17.
//

import Foundation

class RowData: Equatable, Decodable {
    static func == (a: RowData, b: RowData) -> Bool {
        return true
    }
}
