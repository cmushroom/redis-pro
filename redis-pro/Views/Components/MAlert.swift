//
//  MAlert.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/7/14.
//

import Foundation
import Cocoa
import Logging

class MAlert {
    private let alert: NSAlert = NSAlert()
    
    let logger = Logger(label: "alert")
    
    func confirm(_ title:String, message:String = "", primaryButton:String = "Ok", secondButton:String = "Cancel", primaryAction: @escaping () -> Void = {}, secondAction: @escaping () -> Void = {}, style:NSAlert.Style = NSAlert.Style.warning) -> Void {
        
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: primaryButton)
        alert.addButton(withTitle: secondButton)
        alert.alertStyle = style
        
        alert.beginSheetModal(for: NSApplication.shared.keyWindow!, completionHandler: { (modalResponse: NSApplication.ModalResponse) -> Void in
            if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                self.logger.info("alert first action")
                primaryAction()
            } else if (modalResponse == NSApplication.ModalResponse.alertSecondButtonReturn) {
                self.logger.info("alert second action")
                secondAction()
            }
        })
    }
    
    
    func show(_ title:String, message:String = "", primaryButton:String = "Ok", primaryAction: @escaping () -> Void = {}, style:NSAlert.Style = NSAlert.Style.warning) -> Void {
        
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: primaryButton)
        alert.alertStyle = style
        
        alert.beginSheetModal(for: NSApplication.shared.keyWindow!, completionHandler: { (modalResponse: NSApplication.ModalResponse) -> Void in
            if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                self.logger.info("alert first action")
                primaryAction()
            }
        })
    }
}
