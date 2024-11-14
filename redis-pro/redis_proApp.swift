//
//  redis_proApp.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/1/19.
//

import Foundation
import SwiftUI
import Logging
import ComposableArchitecture
import FirebaseCore

@main
struct redis_proApp: App {
    private let logger = Logger(label: "app")
    
    // 会造成indexView 多次初始化
    // @Environment(\.scenePhase) var scenePhase
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // settings
    var settingsStore:StoreOf<SettingsStore> = Store(initialState: SettingsStore.State()) {
        SettingsStore()
    }
    
    // 应用启动只初始化一次
    init() {
        // logger
        LoggerFactory().setUp()
    }
    
    @SceneBuilder var body: some Scene {
        
        WindowGroup {
            IndexView(settingStore: self.settingsStore, store: Store(initialState: AppStore.State()) {
                AppStore()
            })
        }
        .commands {
            CommandMenu("New Window") {
                Button(action: openNewWindow) {
                    Text("New Window")
                }
                .keyboardShortcut("T", modifiers: [.command])
            }
        }
        
//        WindowGroup {
//            IndexView(settingStore: settingsStore)
//                .onAppear {
//                    self.settingsStore.send(.initial)
//                }
//        }
//        .commands {
//            RedisProCommands()
//        }
        
        WindowGroup("AboutView") {
            AboutView()
        }.handlesExternalEvents(matching: Set(arrayLiteral: "AboutView"))
        
        Settings {
            SettingsView(store: settingsStore)
        }
    }
    func openNewWindow() {
        if let keyWindow = NSApplication.shared.keyWindow {
                    // 获取当前的窗口控制器
                    if let windowController = keyWindow.windowController {
                        
                        let store = Store(initialState: AppStore.State()) {
                            AppStore()
                        }
                        // 创建新的 SwiftUI 视图，并用 NSHostingViewController 包装
                        let newViewController = NSHostingController(rootView: IndexView(settingStore: self.settingsStore, store: store))
                        
                        // 为新的窗口内容创建一个新 tab
                        windowController.addTab(with: newViewController, matchingSizeOf: keyWindow)
                    }
                }
    }
}

extension NSWindowController {
    func addTab(with viewController: NSViewController, matchingSizeOf window: NSWindow) {
           // 获取当前窗口的尺寸
           let windowFrame = window.frame
           
           // 创建一个新的 NSWindow，并设置为与原窗口大小一致
           let newWindow = NSWindow(
               contentRect: windowFrame,
               styleMask: [.titled, .closable, .resizable, .miniaturizable],
               backing: .buffered,
               defer: false
           )
           
           // 将 SwiftUI 视图嵌入到新窗口的内容视图中
           newWindow.contentViewController = viewController
           
           // 添加新的 tab，并保证窗口大小一致
           self.window?.addTabbedWindow(newWindow, ordered: .above)
       }
}


class AppDelegate: NSObject, NSApplicationDelegate {
    let logger = Logger(label: "redis-app")
    
    func applicationWillFinishLaunching(_: Notification) {
        logger.info("redis pro before launch ...")
        
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        logger.info("redis pro launch complete")
        
        // firebase
        FirebaseApp.configure()
        
        let colorSchemeValue = UserDefaults.standard.string(forKey: UserDefaulsKeysEnum.AppColorScheme.rawValue) ?? ColorSchemeEnum.SYSTEM.rawValue
        if colorSchemeValue == ColorSchemeEnum.SYSTEM.rawValue {
            NSApp.appearance = nil
        } else {
            NSApp.appearance = NSAppearance(named:  colorSchemeValue == ColorSchemeEnum.DARK.rawValue ? .darkAqua : .aqua)
        }
        logger.info("redis pro launch, set color scheme complete...")
        
    }
    
    func applicationWillTerminate(_ notification: Notification)  {
        logger.info("redis pro application will terminate...")
    }
    
    func didFinishLaunchingWithOptions(_ notification: Notification)  {
        logger.info("redis didFinishLaunchingWithOptions...")
    }
    
    func applicationWillUnhide(_: Notification) {
        logger.info("redis pro applicationWillUnhide...")
    }
    func applicationDidHide(_ notification:Notification) {
        logger.info("redis pro applicationDidHide...")
    }
    
    
    func applicationWillBecomeActive(_ notification: Notification) {
        logger.info("redis applicationWillBecomeActive...")
    }
    
    func applicationWillResignActive(_:Notification) {
        logger.info("redis pro applicationWillResignActive...")
    }

    func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows: Bool) -> Bool {
        logger.info("redis pro applicationShouldHandleReopen, hasVisibleWindows: \(hasVisibleWindows)")
        return true
    }

    func applicationShouldOpenUntitledFile(_:NSApplication) -> Bool {
        logger.info("redis pro applicationShouldOpenUntitledFile...")
        return true

    }
    
}
