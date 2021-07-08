//
//  RedisProCommands.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/5/21.
//

import SwiftUI
import Cocoa

struct RedisProCommands: Commands {
    
    private struct HelpCommands: View {
        @FocusedBinding(\.versionUpgrade) var versionUpgrade:Int?
        
        var body: some View {
            Button("Check Update") {
                versionUpgrade? += 1
            }
        }
    }
    
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
            HelpCommands()
        }
    }
}


private struct VersionUpgradeKey: FocusedValueKey {
    typealias Value = Binding<Int>
}

extension FocusedValues {
    var versionUpgrade: Binding<Int>? {
        get { self[VersionUpgradeKey.self] }
        set { self[VersionUpgradeKey.self] = newValue }
    }
}
