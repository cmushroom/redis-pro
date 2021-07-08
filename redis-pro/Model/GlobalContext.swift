//
//  GlobalContext.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/15.
//

import Foundation
import RediStack

class GlobalContext:ObservableObject, CustomStringConvertible {
    @Published var alertVisible:Bool = false
    var alertTitle:String = ""
    var alertMessage:String = ""
    var showSecondButton:Bool = false
    var primaryButtonText:String = "Ok"
    var secondButtonText:String = "Cancel"
    var primaryAction:() throws -> Void = {}
    
    @Published var loading:Bool = false
    @Published var versionUpgrade:Int = 0

    
    func showError(_ error:Error) -> Void {
        alertVisible = true
        if error is BizError {
            alertMessage = (error as! BizError).message
        } else if error is RedisError {
            alertMessage = (error as! RedisError).message
        } else {
            alertMessage = "\(error)"
        }
    }
    
    func showAlert(_ alertTitle:String, alertMessage:String = "", primaryAction: @escaping () throws -> Void = {}, primaryButtonText:String = "Ok", showSecondButton:Bool = false) -> Void {
        self.alertVisible = true
        self.alertTitle = alertTitle
        self.alertMessage = alertMessage
        self.primaryAction = primaryAction
        self.primaryButtonText = primaryButtonText
        self.showSecondButton = showSecondButton
    }

    
    var description: String {
        return "GlobalContext:[alertVisible:\(alertVisible), loading:\(loading), showSecondButton: \(showSecondButton), primaryButtonText:\(primaryButtonText)]"
    }
}
