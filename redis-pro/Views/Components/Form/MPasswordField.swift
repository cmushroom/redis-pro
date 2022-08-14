//
//  NPasswordField.swift
//  redis-pro
//
//  Created by chengpan on 2021/12/12.
//

import SwiftUI
import Logging

struct MPasswordField: View {
    @Binding var value:String
    var placeholder:String = "Password"
    @State private var isEditing = false
    var onCommit:(() -> Void)?
    
    @State private var visible:Bool = false
    var disabled = false
    
    let logger = Logger(label: "pass-field")
    
    @ViewBuilder
    private var textField: some View {
        if #available(macOS 12.0, *) {
            TextField("", text: $value, prompt: Text(placeholder))
                .onSubmit {
                    onCommit?()
                }
        } else {
            TextField(placeholder, text: $value, onCommit: {onCommit?()})
        }
    }
    
    @ViewBuilder
    private var secureField: some View {
        if #available(macOS 12.0, *) {
            SecureField("", text: $value, prompt: Text(placeholder))
                .onSubmit {
                    onCommit?()
                }
        } else {
            SecureField(placeholder, text: $value, onCommit: {onCommit?()})
        }
    }
    
    @ViewBuilder
    private var field: some View {
        if visible {
            textField
        } else {
            secureField
                .textContentType(.password)
        }
    }
    
    var body: some View {
        HStack(alignment: .center) {
            field
                .labelsHidden()
                .lineLimit(1)
                .disabled(disabled)
                .multilineTextAlignment(.leading)
                .font(.body)
                .disableAutocorrection(true)
                .textFieldStyle(PlainTextFieldStyle())
                .onHover { inside in
                    self.isEditing = inside
                }
            
            Button(action: {
                visible.toggle()
            }) {
                Image(systemName: !self.visible ? "eye.slash" : "eye")
                    .accentColor(.gray)
            }
            .onHover { inside in
                if inside {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
            .padding(EdgeInsets(top: 0, leading: 2, bottom: 0, trailing: 2))
            .buttonStyle(PlainButtonStyle())
            .contentShape(Circle())
        }
        .padding(EdgeInsets(top: 3, leading: 4, bottom: 3, trailing: 4))
        .background(Color.init(NSColor.textBackgroundColor))
        .cornerRadius(MTheme.CORNER_RADIUS)
        .overlay(
            RoundedRectangle(cornerRadius: MTheme.CORNER_RADIUS).stroke(Color.gray.opacity(!disabled && isEditing ?  0.4 : 0.2), lineWidth: 1)
        )
    }
    
    func showPassAction() -> Void {
        self.visible.toggle()
    }
}

//struct NPasswordField_Previews: PreviewProvider {
//    static var previews: some View {
//        NPasswordField()
//    }
//}
