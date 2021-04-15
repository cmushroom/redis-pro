//
//  IndexView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/8.
//

import SwiftUI

struct IndexView: View {
    @StateObject var redisInstanceModel:RedisInstanceModel = RedisInstanceModel(redisModel: RedisModel())
    @StateObject var globalContext:GlobalContext = GlobalContext()
    
    var body: some View {
        if (!redisInstanceModel.isConnect) {
            LoginView()
                .environmentObject(redisInstanceModel)
                .environmentObject(globalContext)
                .onAppear {
                    logger.info("redis pro login view init complete")
                }
                .alert(isPresented: $redisInstanceModel.alertContext.visible) {
                    Alert(title: Text("warnning"), message: Text(redisInstanceModel.alertContext.msg), dismissButton: .default(Text("OK")))
                }
            
        } else {
            HomeView(redisInstanceModel: redisInstanceModel)
                .onAppear {
                    logger.info("redis pro home view init complete")
                }
                .onDisappear {
                    logger.info("redis pro home view destroy...")
                    redisInstanceModel.close()
                }
                .alert(isPresented: $redisInstanceModel.alertContext.visible) {
                    Alert(title: Text("warnning"), message: Text(redisInstanceModel.alertContext.msg), dismissButton: .default(Text("OK")))
                }
        }
    }
}

struct IndexView_Previews: PreviewProvider {
    static var previews: some View {
        IndexView()
    }
}
