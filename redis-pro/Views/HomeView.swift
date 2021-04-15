//
//  HomeView.swift
//  redis-pro
//
//  Created by chengpan on 2021/4/4.
//

import SwiftUI
import Logging

struct HomeView: View {
    var redisInstanceModel:RedisInstanceModel
    
    let logger = Logger(label: "home-view")
    
    var body: some View {
        RedisKeysListView(redisInstanceModel:redisInstanceModel)
            .onAppear {
                logger.info("redis pro home view init complete")
            }
            .onDisappear {
                logger.info("redis pro home view destroy...")
                redisInstanceModel.close()
            }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(redisInstanceModel: RedisInstanceModel(redisModel: RedisModel()))
    }
}
