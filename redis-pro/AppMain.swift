//
//  App.swift
//  redis-pro
//
//  Created by chengpan on 2024/9/22.
//

import SwiftUI

struct AppMain: App {
    @SceneBuilder var body: some Scene {
        WindowGroup {
            Text("wwww")
        }
        .commands {
            CommandMenu("New Window") {
                Button(action: openNewWindow) {
                    Text("New Window")
                }
                .keyboardShortcut("T", modifiers: [.command])
            }
        }
    }
    
    func openNewWindow() {
        // 通过某种方式标记新窗口
        _ = WindowGroup {
            Text("wwww")
        }
        
    }
}
