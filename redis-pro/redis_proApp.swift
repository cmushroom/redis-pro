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

@main
struct redis_proApp: App {
    @StateObject var globalContext:GlobalContext = GlobalContext()
    @AppStorage("User.colorSchemeValue")
    private var colorSchemeValue:String = ColorSchemeEnum.AUTO.rawValue
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        // logger
        LoggerFactory().setUp()
    }
    
    var body: some Scene {
        WindowGroup {
            IndexView()
                .preferredColorScheme(ColorSchemeEnum.getColorScheme(colorSchemeValue))
                .environmentObject(globalContext)
                .onAppear {
                    VersionManager(globalContext: globalContext).checkUpdate()
                }
        }
        .commands {
            RedisProCommands(globalContext: globalContext)
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
