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
    //    private var redisFavoriteModel: RedisFavoriteModel = RedisFavoriteModel()
    
    
    let logger = Logger(label: "redis-app")
    
    var body: some Scene {
        WindowGroup {
            IndexView()
        }
        .commands {
            //            LandmarkCommands()
        }
        
    }
}
