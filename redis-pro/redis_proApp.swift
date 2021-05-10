//
//  redis_proApp.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/1/19.
//

import SwiftUI
import Logging

@main
struct redis_proApp: App {
    let logger = Logger(label: "redis-app")
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            IndexView()
            //            ContentView()
        }
        .commands {
            //            LandmarkCommands()
        }
        
        
    }
}


class AppDelegate: NSObject, NSApplicationDelegate {
    let logger = Logger(label: "redis-app")
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        logger.info("redis pro launch complete")
    }
    
    func applicationWillTerminate(_ notification: Notification)  {
        logger.info("redis pro will close...")
    }
}
