//
//  IconButton.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/9.
//

import SwiftUI
import Logging

struct IconButton: View {
    @EnvironmentObject var globalContext:GlobalContext
    var icon:String
    var name:String?
    var disabled:Bool = false
    var isConfirm:Bool = false
    var confirmTitle:String?
    var confirmMessage:String?
    var confirmPrimaryButtonText:String?
    
    var action: () throws -> Void = {print("icon button action")}
    
    let logger = Logger(label: "icon-button")
    
    var body: some View {
        Button(action: doAction) {
            HStack(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/, spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 12.0))
                    .padding(0)
                if name != nil {
                    Text(name!)
                }
            }
        }
        .buttonStyle(BorderedButtonStyle())
        .disabled(disabled)
        .onHover { inside in
            if !disabled && inside {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
        
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
}

struct IconButton_Previews: PreviewProvider {
    static var previews: some View {
        IconButton(icon: "plus", name: "Add")
    }
}
