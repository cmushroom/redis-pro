//
//  redis_proApp.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/1/19.
//

import SwiftUI

@main
struct redis_proApp: App {
    private var redisFavoriteModel: RedisFavoriteModel = RedisFavoriteModel()
    
    var body: some Scene {
        WindowGroup {
            LoginView()
//            ContentView()
                .environmentObject(redisFavoriteModel)
                .onAppear {
                    redisFavoriteModel.loadAll()
                }
        }
        .commands {
            LandmarkCommands()
        }
    }
}
