//
//  MSecureField.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/7/22.
//

import SwiftUI


import Logging

struct MSecureField: View {
    @Binding var value:String
    var placeholder:String = "Password"
    @State private var isEditing = false
    var onCommit:() -> Void = {}
    
    @State private var showPass:Bool = false
    
    let logger = Logger(label: "secure-field")
    
    @ViewBuilder
    private var field: some View {
        if showPass {
//            TextField(placeholder, text: $value, onEditingChanged: { isEditing in
//                self.isEditing = isEditing
//            }, onCommit: doCommit)
            NTextField(stringValue: $value, placeholder: placeholder, onCommit: onCommit)
        } else {
            SecureField(placeholder, text: $value, onCommit: doCommit)
        }
    }
    
    var body: some View {
        HStack(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/, spacing: 2) {
            field
                .multilineTextAlignment(/*@START_MENU_TOKEN@*/.leading/*@END_MENU_TOKEN@*/)
                .font(.body)
                .lineLimit(1)
                .disableAutocorrection(true)
                .textFieldStyle(PlainTextFieldStyle())
                .onHover { inside in
                    self.isEditing = inside
                }
            
            MIcon(icon: showPass ? "eye" : "eye.slash", fontSize: MTheme.FONT_SIZE_BUTTON, action: showPassAction)
                .padding(0)
        }
        .padding(EdgeInsets(top: 3, leading: 4, bottom: 3, trailing: 4))
        .background(Color.init(NSColor.textBackgroundColor))
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4).stroke(Color.gray.opacity(isEditing ?  0.4 : 0.2), lineWidth: 1)
        )
    }
    
    func doCommit() -> Void {
        doAction()
    }
    
    func showPassAction() -> Void {
        self.showPass.toggle()
    }
    
    func doAction() -> Void {
        logger.info("on textField commit, value: \(value)")
        onCommit()
    }
}
struct MSecureField_Previews: PreviewProvider {
    
    @State static var text:String = "pass"
    static var previews: some View {
        MSecureField(value: $text)
    }
}
