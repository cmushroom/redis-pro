//
//  MIntField.swift
//  redis-pro
//
//  Created by chengpan on 2021/12/11.
//

import SwiftUI
import Logging

struct MIntField: View {
    @Binding var value:Int
    var placeholder:String?
    var suffix:String?
    @State private var isEditing = false
    var onCommit:() throws -> Void = {}
    var disabled:Bool = false
    var autoCommit:Bool = true
    
    // 是否有编辑过，编回过才会触commit
    @State private var isEdited:Bool = false
    var autoTrim:Bool = false
    
    let logger = Logger(label: "int-field")
    
    var body: some View {
        HStack(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/, spacing: 2) {
            if #available(macOS 12.0, *) {
                TextField("", value: $value, formatter: NumberHelper.intFormatter, prompt: Text(placeholder ?? ""))
                    .onSubmit {
                        doCommit()
                    }
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
            } else {
                // Fallback on earlier versions
                
                TextField(placeholder ?? "", value: $value, formatter: NumberHelper.intFormatter, onEditingChanged: { isEditing in
                    self.isEditing = isEditing
                    if isEditing {
                        self.isEdited = true
                    }
                }, onCommit: doCommit)
                    .disabled(disabled)
                    .multilineTextAlignment(.leading)
                    .lineLimit(1)
                    .font(.body)
                    .disableAutocorrection(true)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onHover { inside in
                        self.isEditing = inside
                    }
            }
            
            if suffix != nil {
                MIcon(icon: suffix!, fontSize: MTheme.FONT_SIZE_BUTTON, action: doAction)
                    .padding(0)
            }
        }
        .padding(EdgeInsets(top: 3, leading: 4, bottom: 3, trailing: 4))
        .background(Color.init(NSColor.textBackgroundColor))
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4).stroke(Color.gray.opacity(!disabled && isEditing ?  0.4 : 0.2), lineWidth: 1)
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

//struct MIntField_Previews: PreviewProvider {
//    static var previews: some View {
//        MIntField()
//    }
//}
