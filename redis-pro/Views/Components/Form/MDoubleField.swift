//
//  MDoubleField.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/5/7.
//

import SwiftUI
import Logging

struct MDoubleField: View {
    @Binding var value:Double
    var placeholder:String?
    @State private var isEditing = false
    var onCommit:(() -> Void)?
    
    // 是否有编辑过，编辑过才会触commit
    @State private var isEdited:Bool = false
    
    
    let logger = Logger(label: "double-field")
    
    @ViewBuilder
    private var field: some View {
        if #available(macOS 12.0, *) {
            TextField("", value: $value, formatter: NumberHelper.doubleFormatter, prompt: Text(placeholder ?? ""))
                .onSubmit {
                    doCommit()
                }
        } else {
            TextField(placeholder ?? "", value: $value, formatter: NumberHelper.doubleFormatter, onEditingChanged: { isEditing in
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
                .multilineTextAlignment(.leading)
                .font(.body)
                .disableAutocorrection(true)
                .textFieldStyle(PlainTextFieldStyle())
                .onHover { inside in
                    self.isEditing = inside
                }
        }
        .padding(EdgeInsets(top: 3, leading: 4, bottom: 3, trailing: 4))
        .background(Color.init(NSColor.textBackgroundColor))
        .cornerRadius(MTheme.CORNER_RADIUS)
        .overlay(
            RoundedRectangle(cornerRadius: MTheme.CORNER_RADIUS).stroke(Color.gray.opacity(isEditing ?  0.4 : 0.2), lineWidth: 1)
        )
    }
    
    func doCommit() -> Void {
        if self.isEdited {
            self.isEdited = false
            logger.info("on double field commit, value: \(value)")
            onCommit?()
        }
    }
}

struct MDoubleField_Previews: PreviewProvider {
    @State static var v:Double = 0
    @State static var text:String = "0"
    
    static var previews: some View {
        VStack {
            TextField("sfsfdfdf", text: $text)
            MDoubleField(value: $v)
            Text(String(v))
            Text(text)
        }
    }
}
