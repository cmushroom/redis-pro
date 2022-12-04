//
//  RedisProCommands.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/5/21.
//

import SwiftUI
import Cocoa
import Logging
import ComposableArchitecture

struct RedisProCommands: Commands {
    
    let logger = Logger(label: "commands")
    
    var body: some Commands {
        SidebarCommands()
        
        CommandGroup(replacing: CommandGroupPlacement.toolbar) {
            Button("New Tab", action: {

                if let currentWindow = NSApp.keyWindow,
                    let windowController = currentWindow.windowController {
                    windowController.newWindowForTab(nil)
                    if let newWindow = NSApp.keyWindow,
                       currentWindow != newWindow {
                        currentWindow.addTabbedWindow(newWindow, ordered: .above)
                    }
                }
                
            })
            .keyboardShortcut("t", modifiers: [.command])
        }
        
        CommandGroup(replacing: CommandGroupPlacement.help) {
            CheckUpdateCommands()
            HomeCommands()
            AboutCommands()
        }
    }
}
