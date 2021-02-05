//
//  redis_proApp.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/1/19.
//

import SwiftUI

@main
struct redis_proApp: App {
    @StateObject private var modelData = ModelData()
    
    var body: some Scene {
        WindowGroup {
            Login()
//            ContentView()
//                .environmentObject(modelData)
        }
        .commands {
            LandmarkCommands()
        }
    }
}
