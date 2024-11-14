//
//  App.swift
//  redis-pro
//
//  Created by chengpan on 2024/9/22.
//

import SwiftUI

struct App: App {
    @SceneBuilder var body: some Scene {
        WindowGroup {
            ContentView()
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
        let newWindow = WindowGroup {
            ContentView(tag: UUID().uuidString) // 每个窗口都有独特的 tag
        }
        newWindow.body
    }
}

#Preview {
    App()
}
