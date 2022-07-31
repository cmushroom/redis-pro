//
//  redis_proApp.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/1/19.
//

import Foundation
import SwiftUI
import AppCenter
import AppCenterAnalytics
import AppCenterCrashes
import Logging
import Cocoa
import ComposableArchitecture

@main
struct redis_proApp: App {
    
    @Environment(\.scenePhase) var scenePhase
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    let settingsStore = Store(initialState: SettingsState(), reducer: settingsReducer, environment: SettingsEnvironment())
    let logger = Logger(label: "app")
    
    // 应用启动只初始化一次
    init() {
        // logger
        LoggerFactory().setUp()
    }
    
    var body: some Scene {
        
        WindowGroup {
            IndexView()
                .onChange(of: scenePhase) { newPhase in
                    if newPhase == .active {
                        logger.info("app active")
                    } else if newPhase == .inactive {
                        logger.info("app inactive")
//                        NSApp.hide(self)
//                        NSApp.miniaturizeAll(self)
                    } else if newPhase == .background {
                        logger.info("app background")
                    }
                }
        }
        .commands {
            RedisProCommands()
        }
        
        WindowGroup("AboutView") {
            AboutView()
        }.handlesExternalEvents(matching: Set(arrayLiteral: "AboutView"))
        
        
        
        Settings {
            SettingsView(store: settingsStore)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    let logger = Logger(label: "redis-app")
    
    func applicationWillFinishLaunching(_: Notification) {
        logger.info("redis pro before launch ...")
        
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        logger.info("redis pro launch complete")
        // appcenter
        AppCenter.start(withAppSecret: "310d1d33-2570-46f9-a60d-8a862cdef6c7", services:[
            Analytics.self,
            Crashes.self
        ])
        
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
//        NSApp.mainWindow?.makeKeyAndOrderFront(self)
//        (notification.object as? NSApplication)?.windows.first?.makeKeyAndOrderFront(self)
    }
    
    func applicationWillResignActive(_:Notification) {
        logger.info("redis pro applicationWillResignActive...")
    }
    //    func applicationWillUpdate(_:Notification) {
    //        logger.info("redis pro applicationWillUpdate...")
    //    }
    
    
//    func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows: Bool) -> Bool {
//        logger.info("redis applicationShouldHandleReopen...")
//        return true
//    }
//
//    func applicationShouldOpenUntitledFile(_:NSApplication) -> Bool {
//        logger.info("redis applicationShouldOpenUntitledFile...")
//        return true
//
//    }
    
}

//extension AppDelegate: NSWindowDelegate {
//
//    func windowDidMiniaturize(_: Notification) {
//    }
//}
