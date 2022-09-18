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
                    logger.info("redis pro scene phase change: \(newPhase)")
                    if newPhase == .active {
                    } else if newPhase == .inactive {
                    } else if newPhase == .background {
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
        
        // 必须加上 applicationShouldHandleReopen 方法才会被执行，参考: https://developer.apple.com/forums/thread/706772?answerId=715063022#715063022
        // 关闭时还会有问题，无法唤起
//        NSApplication.shared.delegate = self
        
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
        if let window = NSApp.windows.first {
                window.deminiaturize(nil)
            }
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
