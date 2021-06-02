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
    @Binding var value:Int
    var suffix:String?
    var onCommit:() throws -> Void = {}
    var autoCommit:Bool = true
    
    var body: some View {
        let valueProxy = Binding<String>(
            get: { String(Int(self.value)) },
            set: {
                if let value = NumberFormatter().number(from: $0) {
                    self.value = value.intValue
                }
            }
        )
        
        HStack(alignment: .center) {
            if !label.isEmpty {
                FormLabel(label: label, width: labelWidth)
            }
            MTextField(value: valueProxy, placeholder: placeholder ?? label, suffix: suffix, onCommit: onCommit, autoCommit: autoCommit)
        }
    }
}

struct FormItemInt_Previews: PreviewProvider {
    @State static var v:Int = 0
    
    static var previews: some View {
        FormItemInt(label: "name", value: $v)
    }
}
