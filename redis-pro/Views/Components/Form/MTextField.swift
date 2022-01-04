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
    var autoCommit:Bool = true
    
    // 是否有编辑过，编回过才会触commit
    @State private var isEdited:Bool = false
    var autoTrim:Bool = false
    
    private var adapterValue: Binding<String> {
        Binding<String>(get: {
            return self.value
        }, set: {
            self.value = autoTrim ? $0.trimmingCharacters(in: .whitespacesAndNewlines) : $0
        })
    }
    
    let logger = Logger(label: "text-field")
    
    
    @ViewBuilder
    private var field: some View {
        if #available(macOS 12.0, *) {
            TextField("", text: adapterValue, prompt: Text(placeholder ?? ""))
                .onSubmit {
                    doCommit()
                }
        } else {
            TextField(placeholder ?? "", text: adapterValue, onEditingChanged: { isEditing in
                self.isEditing = isEditing
                if isEditing {
                    self.isEdited = true
                }
            }, onCommit: doCommit)
        }
    }
    
    var body: some View {
        HStack(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/, spacing: 2) {
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
            
            if suffix != nil {
                MIcon(icon: suffix!, fontSize: MTheme.FONT_SIZE_BUTTON, action: doAction)
                    .padding(0)
            }
        }
        .padding(EdgeInsets(top: 3, leading: 4, bottom: 3, trailing: 4))
        .background(Color.init(NSColor.textBackgroundColor))
        .cornerRadius(MTheme.CORNER_RADIUS)
        .overlay(
            RoundedRectangle(cornerRadius: MTheme.CORNER_RADIUS).stroke(Color.gray.opacity(!disabled && isEditing ?  0.4 : 0.2), lineWidth: 1)
        )
    }
    
    func doCommit() -> Void {
        if autoCommit && self.isEdited {
            self.isEdited = false
            doAction()
        }
    }
    
    func doAction() -> Void {
        logger.info("on textField commit, value: \(value)")
        do {
            try onCommit()
        } catch {
            MAlert.error(error)
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
