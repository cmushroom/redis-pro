//
//  FormItemInt.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/1/28.
//

import SwiftUI

struct FormItemInt: View {
    var label:String
    var labelWidth:CGFloat = 80
    var placeholder:String?
    var tips:LocalizedStringKey?
    @Binding var value:Int
    var suffix:String?
    var onCommit:(() -> Void)?
    
    
    var body: some View {
        
        HStack(alignment: .center) {
            if !label.isEmpty {
                FormLabel(label: label, width: labelWidth)
            }
//            NIntField(value: $value, placeholder: placeholder ?? label, onCommit: onCommit)
//            MTextField(value: valueProxy, placeholder: placeholder ?? label, suffix: suffix, onCommit: onCommit, autoCommit: autoCommit)
            MIntField(value: $value, placeholder: placeholder ?? label, onCommit: onCommit).help(tips ?? "")
            if(tips != nil) {
                MIcon(icon: "questionmark.circle", fontSize: 12).help(tips!)
            }
        }
    }
}

struct FormItemInt_Previews: PreviewProvider {
    @State static var v:Int = 0
    
    static var previews: some View {
        FormItemInt(label: "name", value: $v)
    }
}
