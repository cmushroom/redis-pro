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

@main
struct redis_proApp: App {
    @AppStorage("User.colorSchemeValue")
    private var colorSchemeValue:String = ColorSchemeEnum.AUTO.rawValue
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // 应用启动只初始化一次
    init() {
        // logger
        LoggerFactory().setUp()
    }
    
    var body: some Scene {
        WindowGroup {
            IndexView()
                .preferredColorScheme(ColorSchemeEnum.getColorScheme(colorSchemeValue))
        }
        
        WindowGroup("AboutView") {
              AboutView()
          }.handlesExternalEvents(matching: Set(arrayLiteral: "AboutView"))
          
        .commands {
            RedisProCommands()
        }
        
        Settings {
            SettingsView()
                .preferredColorScheme(ColorSchemeEnum.getColorScheme(colorSchemeValue))
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    let logger = Logger(label: "redis-app")
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        logger.info("redis pro launch complete")
        
        // appcenter
        AppCenter.start(withAppSecret: "310d1d33-2570-46f9-a60d-8a862cdef6c7", services:[
            Analytics.self,
            Crashes.self
        ])
        
    }
    
    func applicationWillTerminate(_ notification: Notification)  {
        logger.info("redis pro will close...")
    }
    
    func didFinishLaunchingWithOptions(_ notification: Notification)  {
        logger.info("redis didFinishLaunchingWithOptions...")
    }
    
    
}
