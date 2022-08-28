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
    
    var onCommit: (() -> Void)?
    var autoCommit:Bool = true
    // allow edit
    var editable: Bool = true
    
    @State private var isEditing = false
    
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
    private var readonlyField: some View {
        if #available(macOS 12.0, *) {
            Text(self.value)
                .textSelection(.enabled)
        } else {
            Text(self.value)
        }
    }
    
    @ViewBuilder
    private var editField: some View {
        if #available(macOS 12.0, *) {
            TextField("", text: adapterValue, prompt: Text(placeholder ?? ""))
                .onSubmit {
                    doCommit()
                }
        } else {
            TextField(placeholder ?? "", text: adapterValue, onCommit: doCommit)
        }
    }
    
    
    @ViewBuilder
    private var field: some View {
        if editable {
            editField
        } else {
            readonlyField
        }
    }
    
    var body: some View {
        HStack(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/, spacing: 2) {
            field
                .labelsHidden()
                .lineLimit(1)
                .multilineTextAlignment(.leading)
                .font(.body)
                .disableAutocorrection(true)
                .textFieldStyle(PlainTextFieldStyle())
                .onHover { inside in
                    self.isEditing = inside
                }
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(EdgeInsets(top: 3, leading: 4, bottom: 3, trailing: 4))
        .background(editable ? Color.init(NSColor.textBackgroundColor) : Color.gray.opacity(0.05))
        .cornerRadius(MTheme.CORNER_RADIUS)
        .overlay(
            RoundedRectangle(cornerRadius: MTheme.CORNER_RADIUS).stroke(Color.gray.opacity(editable && isEditing ?  0.4 : 0.2), lineWidth: 1)
        )
    }
    
    func doCommit() -> Void {
        logger.info("on textField commit, value: \(value)")
        onCommit?()
    }
}

struct MTextField_Previews: PreviewProvider {
    @State static var text:String = "aa"
    
    static var previews: some View {
        VStack {
            MTextField(value: $text)
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
