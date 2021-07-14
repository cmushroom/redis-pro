//
//  IndexView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/8.
//

import SwiftUI
import Logging

struct IndexView: View {
    @StateObject var globalContext:GlobalContext = GlobalContext()
    @StateObject var redisInstanceModel:RedisInstanceModel = RedisInstanceModel(redisModel: RedisModel())
    
    @AppStorage("versionUpgrade") var versionUpgrade:Int?
    
    let logger = Logger(label: "index-view")
    
    var body: some View {
        HStack {
            VStack {
                
                if (!redisInstanceModel.isConnect) {
                    LoginView()
                        .environmentObject(redisInstanceModel)
                    
                } else {
                    HomeView()
                        .environmentObject(redisInstanceModel)
                        .navigationTitle(redisInstanceModel.redisModel.name)
                }
            }
        }
        .environmentObject(globalContext)
        .onAppear {
            redisInstanceModel.setUp(globalContext)
        }
        .overlay(MSpin(loading: globalContext.loading))
        .alert(isPresented: $globalContext.alertVisible) {
            globalContext.showSecondButton ? Alert(title: Text(globalContext.alertTitle), message: Text(globalContext.alertMessage),
                                                   primaryButton: .default(Text(globalContext.primaryButtonText),
                                                                           action: doAction),
                                                   secondaryButton: .cancel(Text(globalContext.secondButtonText), action: cancelAction)) : Alert(title: Text(globalContext.alertTitle), message: Text(globalContext.alertMessage), dismissButton: .default(Text(globalContext.primaryButtonText)))
        }
        
    }
    
    
    func doAction() -> Void {
        logger.info("alert ok action ...")
        do {
            try globalContext.primaryAction()
        } catch {
            globalContext.showError(error)
        }
        
    }
    func cancelAction() -> Void {
        logger.info("alert cancel action ...")
        logger.info("redis instance : \(redisInstanceModel.redisModel)")
    }
}

struct IndexView_Previews: PreviewProvider {
    static var previews: some View {
        IndexView()
    }
}
