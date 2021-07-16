//
//  MAlert.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/7/14.
//

import Foundation
import Cocoa
import Logging
import RediStack

class MAlert {
    private static let defaultPrimaryButton = "Ok"
    private static let defaultSecondButton = "Cancel"
    private static let defaultConfirmAlertStyle = NSAlert.Style.warning
    
    private static let alert: NSAlert = initAlert()
    private static let confirmAlert: NSAlert = initConfirmAlert()
    
    static let logger = Logger(label: "alert")
    
    static func confirm(_ title:String, message:String = "", primaryButton:String = "Ok", secondButton:String = "Cancel", primaryAction: @escaping () -> Void = {}, secondAction: @escaping () -> Void = {}, style:NSAlert.Style = NSAlert.Style.warning) -> Void {
        
        confirmAlert.messageText = StringHelper.ellipses(title, len: 100)
        confirmAlert.informativeText = StringHelper.ellipses(message, len: 200)
        
        confirmAlert.buttons[0].title = primaryButton
        confirmAlert.buttons[1].title = secondButton
//        confirmAlert.addButton(withTitle: secondButton)
        confirmAlert.alertStyle = style
        
        confirmAlert.beginSheetModal(for: NSApplication.shared.keyWindow!, completionHandler: { (modalResponse: NSApplication.ModalResponse) -> Void in
            if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                self.logger.info("alert first action")
                primaryAction()
            } else if (modalResponse == NSApplication.ModalResponse.alertSecondButtonReturn) {
                self.logger.info("alert second action")
                secondAction()
            }
        })
    }
    
    
    static func show(_ title:String, message:String = "", primaryButton:String = "Ok", primaryAction: @escaping () -> Void = {}, style:NSAlert.Style = NSAlert.Style.warning) -> Void {
        
        alert.messageText = title
        alert.informativeText = message
        alert.buttons[0].title = primaryButton
        alert.alertStyle = style
        
        alert.beginSheetModal(for: NSApplication.shared.keyWindow!, completionHandler: { (modalResponse: NSApplication.ModalResponse) -> Void in
            if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                self.logger.info("alert first action")
                primaryAction()
            }
        })
    }
    
    
    static func error(_ error:Error) -> Void {
        var alertMessage = ""
        if error is BizError {
            alertMessage = (error as! BizError).message
        } else if error is RedisError {
            alertMessage = (error as! RedisError).message
        } else {
            alertMessage = "\(error)"
        }
        
        show("Error!", message: alertMessage, primaryButton: defaultPrimaryButton, style: NSAlert.Style.warning)
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
