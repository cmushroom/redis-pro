//
//  NTableColumn.swift
//  redis-pro
//
//  Created by chengpan on 2022/3/27.
//

import Foundation
import AppKit
import SwiftUI
struct NTableColumn {
    var type:TableColumnType = .DEFAULT
    var title:String
    var key:String
    var width:CGFloat?
    var icon: TableIconEnum?
}


extension NSImage.Name {
    static let icon = NSImage.Name("icon-redis")
}

class Icon {
    private static func appIcon() -> NSImage {
        let icon = NSImage(named: .icon)!
        icon.size = NSSize(width: 20, height: 20)
        return icon
    }
    
    static var ICON_APP = appIcon()
}

protocol TableIconImage {
    var image:NSImage { get }
}


enum TableIconEnum: TableIconImage {
    case APP
    
    var image: NSImage {
        switch self {
        case .APP:
            return Icon.ICON_APP
        }
    }
}
