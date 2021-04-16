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
        
                } else {
                    HomeView(redisInstanceModel: redisInstanceModel)
                        .environmentObject(redisInstanceModel)
                        .environmentObject(globalContext)
                }
        
//        ZStack {
//            redisInstanceModel.isConnect ? LoginView()
//                .environmentObject(redisInstanceModel)
//                .environmentObject(globalContext)
//                .opacity(redisInstanceModel.isConnect ? 0 : 1)
//                .zIndex(redisInstanceModel.isConnect ? 0 : 1)
//
//            HomeView(redisInstanceModel: redisInstanceModel)
//                .opacity(redisInstanceModel.isConnect ? 1 : 0)
//                .zIndex(redisInstanceModel.isConnect ? 1 : 0)
//        }
//        .alert(isPresented: $globalContext.alertVisible) {
//            globalContext.showSecondButton ? Alert(title: Text("Confirm"), message: Text(globalContext.message), primaryButton: .default(Text(globalContext.primaryButtonText), action: globalContext.primaryAction), secondaryButton: .cancel(Text(globalContext.secondButtonText))) : Alert(title: Text("warnning"), message: Text(globalContext.message), dismissButton: .default(Text(globalContext.primaryButtonText)))
//        }
    }
}

struct IndexView_Previews: PreviewProvider {
    static var previews: some View {
        IndexView()
    }
}
