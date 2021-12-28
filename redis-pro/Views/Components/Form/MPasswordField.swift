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
    
    @State private var showPass:Bool = false
    
    let logger = Logger(label: "pass-field")
    
    @ViewBuilder
    private var field: some View {
        if showPass {
            NTextField(stringValue: $value, placeholder: placeholder, type: .PLAIN, onCommit: onCommit)
        } else {
            NSecureField(value: $value, placeholder: placeholder, onChange: {}, onCommit: onCommit)
        }
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 2) {
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
        .padding(EdgeInsets(top: 1, leading: 2, bottom: 1, trailing: 2))
        .background(Color.init(NSColor.textBackgroundColor))
        .cornerRadius(0)
//        .overlay(
////            RoundedRectangle(cornerRadius: 4).stroke(Color.gray.opacity(isEditing ?  0.4 : 0.2), lineWidth: 1)
//        )
    }
    
    func showPassAction() -> Void {
        self.showPass.toggle()
    }
}

//struct NPasswordField_Previews: PreviewProvider {
//    static var previews: some View {
//        NPasswordField()
//    }
//}
