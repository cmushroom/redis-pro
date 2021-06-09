//
//  redis_proApp.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/1/19.
//

import SwiftUI
import AppCenter
import AppCenterAnalytics
import AppCenterCrashes
import Logging
import XCGLogger

@main
struct redis_proApp: App {
    @StateObject var globalContext:GlobalContext = GlobalContext()
    
    let logger = Logger(label: "redis-app")
    
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        // logger
        let xcgLogger = XCGLogger.default
        xcgLogger.setup(level: .debug, showLogIdentifier: false, showFunctionName: true, showThreadName: true, showLevel: true, showFileNames: true, showLineNumbers: true, showDate: true, writeToFile: "redis-pro.log", fileLevel: .debug)
        LoggingSystem.bootstrap({
            ClassicLogHandler(label: $0, xcgLogger: xcgLogger)
        })
        
        logger.info("init logger complete...")
    }
    
    var body: some Scene {
        WindowGroup {
            IndexView()
                .environmentObject(globalContext)
        }
        .commands {
            RedisProCommands()
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
