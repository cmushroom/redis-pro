//
//  Messages.swift
//  redis-pro
//
//  Created by chengpan on 2022/5/29.
//

import Foundation
import Cocoa
import Logging
import RediStack

class Messages {
    private static let defaultPrimaryButton = "Ok"
    private static let defaultSecondButton = "Cancel"
    private static let defaultConfirmAlertStyle = NSAlert.Style.warning
    
    private static let alert: NSAlert = initAlert()
    private static let confirmAlert: NSAlert = initConfirmAlert()
    
    static let logger = Logger(label: "alert")
    
    static func confirm(_ title:String, message:String = "", primaryButton:String = "Ok", action: @escaping (() -> Void)) {
        
        DispatchQueue.main.async {
            confirmAlert.messageText = StringHelper.ellipses(title, len: 100)
            confirmAlert.informativeText = StringHelper.ellipses(message, len: 200)
            
            confirmAlert.buttons[0].title = primaryButton
            confirmAlert.buttons[1].title = "Cancel"
            
            confirmAlert.alertStyle = NSAlert.Style.warning
            
            confirmAlert.beginSheetModal(for: NSApplication.shared.keyWindow!, completionHandler: { (modalResponse: NSApplication.ModalResponse) -> Void in
                if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                    self.logger.info("alert ok action")
                    action()
                } else if (modalResponse == NSApplication.ModalResponse.alertSecondButtonReturn) {
                    self.logger.info("alert second action")
                }
            })
        }
    }
    
    static func show(_ title:String) {
        DispatchQueue.main.async {
            alert.messageText = title
            //        alert.informativeText = message
            alert.buttons[0].title = "Ok"
            alert.alertStyle = NSAlert.Style.warning
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
        show(message)
        
    }
    
    private static func initConfirmAlert() -> NSAlert {
        let alert = NSAlert()
        
        alert.addButton(withTitle: defaultPrimaryButton)
        alert.addButton(withTitle: defaultSecondButton)
        alert.alertStyle = defaultConfirmAlertStyle
        return alert
    }
    
    
    private static func initAlert() -> NSAlert {
        let alert = NSAlert()
        
        alert.addButton(withTitle: defaultPrimaryButton)
        alert.alertStyle = defaultConfirmAlertStyle
        return alert
    }
}
