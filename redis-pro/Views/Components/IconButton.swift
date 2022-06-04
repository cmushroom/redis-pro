//
//  IconButton.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/9.
//

import SwiftUI
import Logging
import Cocoa

struct IconButton: View {
    var icon:String
    var name:String
    var disabled:Bool = false
    
    var action: (() -> Void)
    
    let logger = Logger(label: "icon-button")
    
    var body: some View {
        NButton(title: name, action: action, icon: icon, disabled: disabled)
//        .buttonStyle(BorderedButtonStyle())
        .disabled(disabled)
        .onHover { inside in
            if !disabled && inside {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
        
    }
}
