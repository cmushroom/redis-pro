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
    
    private struct CheckUpdateCommands: View {
        var body: some View {
            Button("Check Update") {
                VersionManager().checkUpdate(isNoUpgradeHint: true)
            }
        }
    }
    
    private struct AboutCommands: View {
        
        @Environment(\.openURL) var openURL
        var body: some View {
            Button("About") {
                guard let url = URL(string: "redis-pro://AboutView") else {
                    return
                }
                openURL(url)
            }
        }
    }
    
    private struct HomePageCommands: View {
        @Environment(\.openURL) var openURL
        
        var body: some View {
            Button("Home") {
                guard let url = URL(string: Constants.REPO_URL) else {
                    return
                }
                openURL(url)
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
                
                //                if let currentWindow = NSApp.keyWindow,
                //                   let windowController = currentWindow.windowController {
                //                    windowController.newWindowForTab(nil)
                //                    windowController.contentViewController = NSHostingController(rootView: IndexView())
                //
                //                    if let newWindow = NSApp.keyWindow,
                //                       currentWindow != newWindow {
                //                        currentWindow.setFrame(currentWindow.frame, display: true)
                //                        currentWindow.addTabbedWindow(newWindow, ordered: .above)
                //                    }
                //                }
                
            })
            .keyboardShortcut("t", modifiers: [.command])
        }
        
        CommandGroup(replacing: CommandGroupPlacement.help) {
            CheckUpdateCommands()
            HomePageCommands()
            AboutCommands()
        }
    }
}
