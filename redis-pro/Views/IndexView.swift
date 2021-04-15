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
//        if (!redisInstanceModel.isConnect) {
//            LoginView()
//                .environmentObject(redisInstanceModel)
//                .environmentObject(globalContext)
//                .alert(isPresented: $redisInstanceModel.alertContext.visible) {
//                    Alert(title: Text("warnning"), message: Text(redisInstanceModel.alertContext.msg), dismissButton: .default(Text("OK")))
//                }
//
//        } else {
//            HomeView(redisInstanceModel: redisInstanceModel)
//                .zIndex(<#T##value: Double##Double#>)
//                .alert(isPresented: $redisInstanceModel.alertContext.visible) {
//                    Alert(title: Text("warnning"), message: Text(redisInstanceModel.alertContext.msg), dismissButton: .default(Text("OK")))
//                }
//        }
        
        ZStack {
            LoginView()
                .environmentObject(redisInstanceModel)
                .environmentObject(globalContext)
                .alert(isPresented: $globalContext.alertVisible) {
                    Alert(title: Text("warnning"), message: Text(globalContext.message ?? ""), dismissButton: .default(Text("OK")))
                }
                .opacity(redisInstanceModel.isConnect ? 0 : 1)
                .zIndex(redisInstanceModel.isConnect ? 0 : 1)
            
            HomeView(redisInstanceModel: redisInstanceModel)
                .opacity(redisInstanceModel.isConnect ? 1 : 0)
                .zIndex(redisInstanceModel.isConnect ? 1 : 0)
                .alert(isPresented: $globalContext.alertVisible) {
                    Alert(title: Text("warnning"), message: Text(globalContext.message ?? ""), dismissButton: .default(Text("OK")))
                }
        }
    }
}

struct IndexView_Previews: PreviewProvider {
    static var previews: some View {
        IndexView()
    }
}
