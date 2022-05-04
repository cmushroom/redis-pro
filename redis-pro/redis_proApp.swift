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
//    @AppStorage("User.colorSchemeValue")
//    private var colorSchemeValue:String = ColorSchemeEnum.SYSTEM.rawValue
//    @State var color: ColorScheme?
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
//    @State var appColorScheme = ColorScheme.light
//    var appColorScheme:ColorScheme {
//        // dark light mode
//        if colorSchemeValue == ColorSchemeEnum.DARK.rawValue {
//            return ColorScheme.dark
//        } else if colorSchemeValue == ColorSchemeEnum.LIGHT.rawValue {
//            return ColorScheme.light
//        } else {
//            return colorScheme
//        }
//    }
    
//    let store = Store(initialState: AppState(), reducer: appReducer, environment: AppEnvironment())
    let settingsStore = Store(initialState: globalSettingsState, reducer: settingsReducer, environment: SettingsEnvironment())
    // 应用启动只初始化一次
    init() {
        // logger
        LoggerFactory().setUp()
    }
    
    var body: some Scene {
        WindowGroup {
//            IndexView(store: Store(initialState: AppState(), reducer: appReducer, environment: AppEnvironment()))
            IndexView()
//            Test()
//                .preferredColorScheme(ColorSchemeEnum.SYSTEM.rawValue == colorSchemeValue ? nil : ColorSchemeEnum.LIGHT.rawValue == colorSchemeValue ? .light : .dark)
//            Button("color", action: {
//                print("sdfs")
//                appColorScheme = ColorScheme.light == appColorScheme ? .dark : .light
//            })
        
        }
        .commands {
            RedisProCommands()
        }
        
        WindowGroup("AboutView") {
              AboutView()
//                .preferredColorScheme(appColorScheme)
        }.handlesExternalEvents(matching: Set(arrayLiteral: "AboutView"))

        

        Settings {
            SettingsView(store: settingsStore)
//                .preferredColorScheme(appColorScheme)
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
