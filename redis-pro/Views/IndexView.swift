//
//  IndexView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/8.
//

import SwiftUI
import Logging

struct IndexView: View {
    @StateObject var redisInstanceModel:RedisInstanceModel = RedisInstanceModel(redisModel: RedisModel())
    @EnvironmentObject var globalContext:GlobalContext
    
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
        .onAppear {
            redisInstanceModel.setUp(globalContext)
        }
        .onReceive(globalContext.objectWillChange, perform: { newValue in
        })
        .overlay(MSpin(loading: globalContext.loading))
//        .sheet(isPresented: $globalContext.loading) {
//            HStack(alignment:.center, spacing: 8) {
//                ProgressView()
//                Text("Loading...")
//            }
//            .padding(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12))
//            .frame(width: 200, height: 60)
//            .background(Color.black.opacity(0.5))
//            .cornerRadius(4)
//            .shadow(color: .black.opacity(0.6), radius: 8, x: 4, y: 4)
//            .colorScheme(.dark)
//        }
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
    }
}

struct IndexView_Previews: PreviewProvider {
    static var previews: some View {
        IndexView()
    }
}
