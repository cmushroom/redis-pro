//
//  MButton.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/1/28.
//

import SwiftUI
import AppKit
import Foundation

struct SmallButtonStyle: PrimitiveButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
//            .font(.body)
            .environment(\.sizeCategory, .extraSmall)
            .padding(EdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8))
            .foregroundColor(.primary)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(4)
            .shadow(color: /*@START_MENU_TOKEN@*/.black/*@END_MENU_TOKEN@*/.opacity(0.2), radius: 1, x: 1, y: 1)
    }
}

struct MButton: View {
    @EnvironmentObject var globalContext:GlobalContext
    
    var text:String
    var action: () throws -> Void = {}
    var disabled:Bool = false
    var isConfirm:Bool = false
    var confirmTitle:String?
    var confirmMessage:String?
    var confirmPrimaryButtonText:String?
    var size:String = "normal"
    
    var width:CGFloat {
        100
    }
    
    var body: some View {
        Button(action: doAction) {
            Text(text)
                .font(.system(size: MTheme.FONT_SIZE_BUTTON))
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .padding(.horizontal, 4.0)
        }
        .foregroundColor(Color.primary)
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
                globalContext.confirm(confirmTitle ?? "", alertMessage: confirmMessage ?? "", primaryAction: action, primaryButton: confirmPrimaryButtonText ?? globalContext.primaryButtonText)
            }
        } catch {
            globalContext.showError(error)
        }
        
    }
    
    struct MButton_Previews: PreviewProvider {
        static var previews: some View {
            Group {
                VStack(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/, spacing: 8) {
                    Text(NSLocalizedString("hello", comment: "hello"))
                    Text(LocalizedStringKey("hello"))
                    Text("hello")
                    MButton(text: "Hello", action: {})
                    
                    MButton(text: "SmallButton ", action: {}).buttonStyle(SmallButtonStyle())
                    
                    Button("default", action: {})
                    
                    Button("BorderedButtonStyle", action: {})
                    
                    Button("BorderlessButtonStyle", action: {}).buttonStyle(BorderlessButtonStyle())
                    
                    Button("LinkButtonStyle", action: {}).buttonStyle(LinkButtonStyle())
                    
                    Button("PlainButtonStyle", action: {}).preferredColorScheme(.dark).environment(\.sizeCategory, .small).buttonStyle(PlainButtonStyle())
                    
                
                }
                .preferredColorScheme(.dark)
                .padding(20)
            }
        }
    }
}
