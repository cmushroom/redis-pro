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
        .focusedValue(\.versionUpgrade, $globalContext.versionUpgrade)
        .environmentObject(globalContext)
        .onAppear {
            redisInstanceModel.setUp(globalContext)
        }
        .onChange(of: globalContext.versionUpgrade, perform: {_ in
            checkVersionAction()
        })
        .overlay(MSpin(loading: globalContext.loading))
        .alert(isPresented: $globalContext.alertVisible) {
            globalContext.showSecondButton ? Alert(title: Text(globalContext.alertTitle), message: Text(globalContext.alertMessage),
                                                   primaryButton: .default(Text(globalContext.primaryButtonText),
                                                                           action: doAction),
                                                   secondaryButton: .cancel(Text(globalContext.secondButtonText), action: cancelAction)) : Alert(title: Text(globalContext.alertTitle), message: Text(globalContext.alertMessage), dismissButton: .default(Text(globalContext.primaryButtonText)))
        }
        //                .popover(isPresented: $globalContext.alertVisible, arrowEdge: .bottom) {
        //                    Text("popover")
        //                }
        //        .sheet(isPresented: $globalContext.alertVisible, onDismiss: {
        //            print("on dismiss")
        //        }) {
        //            ModalView("hehe", action: {
        //                //                        globalContext.alertVisible.toggle()
        //            }) {
        //                Text("model ....")
        //                Text("model ....")
        //                Text("model ....")
        //                Text("model ....")
        //                Text("model ....")
        //                Text("model ....")
        //                Text("model ....")
        //                Text("model ....")
        //            }
        //        }
        
        //        ZStack {
        //            LoginView()
        //                .environmentObject(redisInstanceModel)
        //                .environmentObject(globalContext)
        //                .opacity(redisInstanceModel.isConnect ? 0 : 1)
        //                .zIndex(redisInstanceModel.isConnect ? 0 : 1)
        //
        //            HomeView()
        //                .environmentObject(redisInstanceModel)
        //                .environmentObject(globalContext)
        //                .opacity(redisInstanceModel.isConnect ? 1 : 0)
        //                .zIndex(redisInstanceModel.isConnect ? 1 : 0)
        //        }
        //        .alert(isPresented: $globalContext.alertVisible) {
        //            globalContext.showSecondButton ? Alert(title: Text("Confirm"), message: Text(globalContext.message), primaryButton: .default(Text(globalContext.primaryButtonText), action: globalContext.primaryAction), secondaryButton: .cancel(Text(globalContext.secondButtonText))) : Alert(title: Text("warnning"), message: Text(globalContext.message), dismissButton: .default(Text(globalContext.primaryButtonText)))
        //        }
        
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
    
    func checkVersionAction() -> Void {
        VersionManager(globalContext: globalContext).checkUpdate(isNoUpgradeHint: true)
    }
}

struct IndexView_Previews: PreviewProvider {
    static var previews: some View {
        IndexView()
    }
}
