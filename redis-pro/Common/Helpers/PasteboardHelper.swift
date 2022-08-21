//
//  PasteboardHelper.swift
//  redis-pro
//
//  Created by chengpan on 2022/8/20.
//

import Foundation
import Cocoa

class PasteboardHelper {
    
    static func copy(_ value: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(value, forType: .string)
    }
    
}
