//
//  MTextField.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/13.
//

import SwiftUI
import Logging

struct MTextField: View {
    @Binding var value:String
    var placeholder:String?
    var suffix:String?
    @State private var isEditing = false
    var onCommit:() throws -> Void = {}
    var disabled:Bool = false
    @EnvironmentObject var globalContext:GlobalContext
    
    let logger = Logger(label: "text-field")
    
    var body: some View {
        HStack(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/, spacing: 2) {
            TextField(placeholder ?? "", text: $value, onEditingChanged: { isEditing in
                self.isEditing = isEditing
            }, onCommit: doAction)
            .disabled(disabled)
            .font(/*@START_MENU_TOKEN@*/.body/*@END_MENU_TOKEN@*/)
            .disableAutocorrection(true)
            .textFieldStyle(PlainTextFieldStyle())
            .onHover { inside in
                self.isEditing = inside
            }
            
            if suffix != nil {
                MIcon(icon: suffix!, fontSize: 14, action: doAction)
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            }
        }
        .padding(EdgeInsets(top: 3, leading: 4, bottom: 3, trailing: 4))
        .background(Color.white)
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4).stroke(Color.gray.opacity(!disabled && isEditing ?  0.4 : 0.2), lineWidth: 1)
            )
//        .border(Color.gray.opacity(isEditing ?  0.4 : 0.2), width: 1)
    }
    
    func doAction() -> Void {
        logger.info("on textField commit, value: \(value)")
        do {
            try onCommit()
        } catch {
            globalContext.showError(error)
        }
    }
}

struct MTextField_Previews: PreviewProvider {
    @State static var text:String = "aa"
    
    static var previews: some View {
        VStack {
            MTextField(value: $text, suffix: "magnifyingglass")
            Text(text)
            MButton(text: "test")
        }
    }
}


extension NSTextField {
    open override var focusRingType: NSFocusRingType {
        get { .none }
        set { }
    }
}
