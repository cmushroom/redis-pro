//
//  TableContextMenuEnum.swift
//  redis-pro
//
//  Created by chengpan on 2022/8/20.
//

import Foundation
import Cocoa

enum TableContextMenu: String{
    case DELETE = "Delete"
    case EDIT = "Edit"
    
    // copy
    case COPY = "Copy"
    case COPY_SCORE = "Copy Score"
    case COPY_FIELD = "Copy Field"
    case COPY_VALUE = "Copy Value"
    
    // key list
    case RENAME = "Rename"
    // client list
    case KILL = "Kill"
    
    var ext: TableContextMenuExt {
        switch self {
        case .DELETE:
            return .init(keyEquivalent: String(Unicode.Scalar(NSBackspaceCharacter)!))
        case .EDIT:
            return .init(keyEquivalent: "e")
        case .COPY:
            return .init(keyEquivalent: "c")
        case .COPY_SCORE:
            return .init(keyEquivalent: "")
        case .COPY_FIELD:
            return .init(keyEquivalent: "")
        case .COPY_VALUE:
            return .init(keyEquivalent: "")
        case .RENAME:
            return .init(keyEquivalent: "")
        case .KILL:
            return .init(keyEquivalent: "k")
        }
    }
}

struct TableContextMenuExt {
    var keyEquivalent: String
}
