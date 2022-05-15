//
//  Alert.swift
//  redis-pro
//
//  Created by chengpan on 2022/5/3.
//

import Logging
import SwiftUI
import ComposableArchitecture
import RediStack



struct AlertView: View {
    let store:Store<AppAlertState, AlertAction>
    private var logger = Logger(label: "alert-view")
    
    init(_ store: Store<AppAlertState, AlertAction>) {
        logger.info("alert view init...")
        self.store = store
        AlertUtil.initial(store)
    }
    
    var body: some View {
        HStack{
            EmptyView()
        }
        .frame(height: 0)
        .alert(self.store.scope(state: \.alert), dismiss: .clearAlert)
    }
}

class AlertUtil {
    var store:Store<AppAlertState, AlertAction>
    var viewStore: ViewStore<AppAlertState, AlertAction>
    
    static var instance:AlertUtil?
    
    private var logger = Logger(label: "alert-util")
    
    init(_ store: Store<AppAlertState, AlertAction>) {
        logger.info("alert util init...")
        
        self.store = store
        self.viewStore = ViewStore(store)
    }
    
    static func initial(_ store: Store<AppAlertState, AlertAction>) {
        if instance != nil {
            return
        }
        
        AlertUtil.instance = .init(store)
    }
    
    static func show(_ title:String) {
        DispatchQueue.main.async {
            instance?.viewStore.send(.alert)
        }
    }
    static func show(_ error:Error) {
        var message = ""
        if error is BizError {
            message = (error as! BizError).message
        } else if error is RedisError {
            message = (error as! RedisError).message
        } else {
            message = "\(error)"
        }
        DispatchQueue.main.async {
            instance?.viewStore.send(.error(message))
        }
    }
    
    // 确认弹框
    static func confirm(_ title:String, message:String, primaryButton:String = "Ok", action: @escaping (() -> Void)) {
        
        DispatchQueue.main.async {
            instance?.viewStore.send(.confirm(title, message, primaryButton, action))
        }
//        confirmAlert.messageText = StringHelper.ellipses(title, len: 100)
//        confirmAlert.informativeText = StringHelper.ellipses(message, len: 200)
//
//        confirmAlert.buttons[0].title = primaryButton
//        confirmAlert.buttons[1].title = secondButton
////        confirmAlert.addButton(withTitle: secondButton)
//        confirmAlert.alertStyle = style
//
//        confirmAlert.beginSheetModal(for: NSApplication.shared.keyWindow!, completionHandler: { (modalResponse: NSApplication.ModalResponse) -> Void in
//            if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
//                self.logger.info("alert first action")
//                primaryAction()
//            } else if (modalResponse == NSApplication.ModalResponse.alertSecondButtonReturn) {
//                self.logger.info("alert second action")
//                secondAction()
//            }
//        })
    }
    
}
