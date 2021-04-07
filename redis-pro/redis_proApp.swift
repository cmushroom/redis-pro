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
    private var redisInstanceModel:RedisInstanceModel = RedisInstanceModel(redisModel: RedisModel())
    
    let logger = Logger(label: "redis-app")
    
    var body: some Scene {
        WindowGroup {
            if (!redisInstanceModel.isConnect) {
                LoginView()
                    .environmentObject(redisInstanceModel)
                    .onAppear {
                        logger.info("redis pro login view init complete")
                    }
            } else {
                HomeView(redisInstanceModel: redisInstanceModel)
                    .environmentObject(redisInstanceModel)
                    .onAppear {
                        logger.info("redis pro home view init complete")
                    }
            }
            
            
        }
        .commands {
            //            LandmarkCommands()
        }
        
    }
}
