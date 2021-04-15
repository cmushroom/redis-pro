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
    @State private var showAlert = false
    @State private var msg:String = ""
    
    let logger = Logger(label: "textfield")
    
    var body: some View {
        HStack(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/, spacing: 2) {
            TextField(placeholder ?? "", text: $value, onEditingChanged: { isEditing in
                self.isEditing = isEditing
                logger.info("textfield status: \(isEditing)")
            }, onCommit: doAction)
            .font(/*@START_MENU_TOKEN@*/.body/*@END_MENU_TOKEN@*/)
            .disableAutocorrection(true)
            .textFieldStyle(PlainTextFieldStyle())
            .onHover { inside in
                self.isEditing = inside
            }
            
            if suffix != nil {
                MIcon(icon: "magnifyingglass", fontSize: 14, action: doAction)
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            }
        }
        .padding(EdgeInsets(top: 3, leading: 4, bottom: 3, trailing: 4))
        .background(Color.white)
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4).stroke(Color.gray.opacity(isEditing ?  0.4 : 0.2), lineWidth: 1)
            )
        .alert(isPresented: $showAlert) {
            Alert(title: Text("warnning"), message: Text(msg), dismissButton: .default(Text("OK")))
        }
//        .border(Color.gray.opacity(isEditing ?  0.4 : 0.2), width: 1)
//        .cornerRadius(4)
    }
    
    func doAction() -> Void {
        logger.info("on textField commit, value: \(value)")
        do {
            try onCommit()
        } catch {
            showAlert = true
            msg = "\(error)"
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
