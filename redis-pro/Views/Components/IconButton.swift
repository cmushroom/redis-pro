//
//  IconButton.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/9.
//

import SwiftUI
import Logging
import Cocoa

struct IconButton: View {
    var icon:String
    var name:String
    var disabled:Bool = false
    var isConfirm:Bool = false
    var confirmTitle:String?
    var confirmMessage:String?
    var confirmPrimaryButtonText:String?
    
    var action: () throws -> Void = {}
    
    let logger = Logger(label: "icon-button")
    
    var body: some View {
        
        Button(action: doAction) {
//            HStack(alignment: .center, spacing: 1) {
//                Image(systemName: icon)
//                    .font(.system(size: MTheme.FONT_SIZE_BUTTON_ICON))
//                    .padding(0)
//                    .foregroundColor(Color.init(NSColor.textColor))
//                Text(name)
//                    .font(.system(size: MTheme.FONT_SIZE_BUTTON))
//                    .foregroundColor(Color.init(NSColor.textColor))
//            }
            MLabel(name: name, icon: icon)
            .padding(.horizontal, 4.0)
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
                MAlert.confirm(confirmTitle ?? "", message: confirmMessage ?? "", primaryButton: confirmPrimaryButtonText ?? "Ok"
                               , primaryAction: {
                                try? action()
                               })
            }
        } catch {
            MAlert.error(error)
        }
    }
}

struct IconButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .center, spacing: 10) {
            IconButton(icon: "plus", name: "Add")
            
            Label("Add", systemImage: "plus")
            
            Label {
                Text("Add")
                    .font(.system(size: 12))
            } icon: {
                Image(systemName: "plus")
                    .font(.system(size: 11))
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 2, trailing: -5))
            }
        }.padding(/*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
        
    }
}
