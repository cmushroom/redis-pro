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
    var name:String
    var disabled:Bool = false
    var isConfirm:Bool = false
    var confirmTitle:String?
    var confirmMessage:String?
    var confirmPrimaryButtonText:String?
    
    var action: () throws -> Void = {print("icon button action")}
    @Environment(\.colorScheme) var colorScheme
    
    let logger = Logger(label: "icon-button")
    
    var body: some View {
    
        Button(action: doAction) {
            HStack(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/, spacing: 1) {
                Image(systemName: icon)
                    .font(.system(size: MTheme.FONT_SIZE_BUTTON_ICON))
                    .padding(0)
                Text(name)
                    .font(.system(size: MTheme.FONT_SIZE_BUTTON))
            }
            .padding(.horizontal, 4.0)
            .foregroundColor(colorScheme == .dark ? Color.white.opacity(disabled ? 0.4 : 0.9) : nil)
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
                globalContext.confirm(confirmTitle ?? "", alertMessage: confirmMessage ?? "", primaryAction: action, primaryButton: confirmPrimaryButtonText ?? globalContext.primaryButtonText)
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
