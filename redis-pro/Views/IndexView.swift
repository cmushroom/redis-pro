//
//  IndexView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/8.
//

import SwiftUI

struct IndexView: View {
    @StateObject var redisInstanceModel:RedisInstanceModel = RedisInstanceModel(redisModel: RedisModel())
    
    var body: some View {
        if (!redisInstanceModel.isConnect) {
            LoginView()
                .environmentObject(redisInstanceModel)
                .onAppear {
                    logger.info("redis pro login view init complete")
                }
        } else {
            HomeView(redisInstanceModel: redisInstanceModel)
                .onAppear {
                    logger.info("redis pro home view init complete")
                }
        }
    }
}

struct IndexView_Previews: PreviewProvider {
    static var previews: some View {
        IndexView()
    }
}
