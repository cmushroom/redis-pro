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
                .alert(isPresented: $redisInstanceModel.alertContext.visible) {
                    Alert(title: Text("warnning"), message: Text(redisInstanceModel.alertContext.msg), dismissButton: .default(Text("OK")))
                }
            
        } else {
            HomeView(redisInstanceModel: redisInstanceModel)
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
