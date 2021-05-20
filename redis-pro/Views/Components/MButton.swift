//
//  MButton.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/1/28.
//

import SwiftUI

struct MButton: View {
    @EnvironmentObject var globalContext:GlobalContext
    var text:String
    var action: () throws -> Void = {}
    var disabled:Bool = false
    var isConfirm:Bool = false
    var confirmTitle:String?
    var confirmMessage:String?
    var confirmPrimaryButtonText:String?
    
    
    var body: some View {
        Button(text, action: doAction)
            .disabled(disabled)
            .onHover { inside in
                    if !disabled && inside {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
            }
    }
    
    var style:some PrimitiveButtonStyle {
        DefaultButtonStyle()
    }
    
    func doAction() -> Void {
        do {
            if !isConfirm {
                try action()
            } else {
                globalContext.alertVisible = true
                globalContext.showSecondButton = true
                globalContext.alertTitle = confirmTitle ?? ""
                globalContext.alertMessage = confirmMessage ?? ""
                globalContext.primaryAction = action
                if confirmPrimaryButtonText != nil {
                    globalContext.primaryButtonText = confirmPrimaryButtonText!
                }
            }
        } catch {
            globalContext.showError(error)
        }
        
    }
    
    struct MButton_Previews: PreviewProvider {
        static var previews: some View {
            MButton(text: "button ", action: {})
        }
    }
}
