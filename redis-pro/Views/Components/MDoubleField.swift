//
//  MDoubleField.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/5/7.
//

import SwiftUI

struct MDoubleField: View {
    @Binding var value:Double
    var placeholder:String?
    @State private var isEditing = false
    var onCommit:() throws -> Void = {}
    var disabled:Bool = false
    var formatter:Formatter = DoubleFormatter()
    
    var body: some View {
        TextField(placeholder ?? "", value: $value, formatter:formatter, onEditingChanged: { isEditing in
            self.isEditing = isEditing
        }, onCommit: doAction)
        .disabled(disabled)
        .font(/*@START_MENU_TOKEN@*/.body/*@END_MENU_TOKEN@*/)
        .disableAutocorrection(true)
        .textFieldStyle(PlainTextFieldStyle())
        .padding(EdgeInsets(top: 3, leading: 4, bottom: 3, trailing: 4))
        .onHover { inside in
            self.isEditing = inside
        }
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4).stroke(Color.gray.opacity(!disabled && isEditing ?  0.4 : 0.2), lineWidth: 1)
            )
    }
    
    
    func doAction() -> Void {
    }
}

struct MDoubleField_Previews: PreviewProvider {
    @State static var v:Double = 0
    static var previews: some View {
        MDoubleField(value: $v)
    }
}
