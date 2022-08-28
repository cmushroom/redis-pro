//
//  FormItemText.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/1/27.
//

import SwiftUI

struct FormItemText: View {
    var label: String?
    var labelWidth:CGFloat = 80
    var placeholder: String?
    var required:Bool = false
    var editable:Bool = true
    @Binding var value: String
    
    var body: some View {
        HStack(alignment: .center) {
            if label != nil && !label!.isEmpty {
                FormLabel(label: label!, width: labelWidth, required: required)
            }
//            NTextField(stringValue: $value, placeholder: placeholder ?? label ?? "")
//            MNSTextField(text: $value)
            MTextField(value: $value, placeholder: placeholder ?? label, editable: editable)
                .frame(maxWidth: .infinity)
        }
    }
}

struct FormItemText_Previews: PreviewProvider {
    @State static var v: String = "";
    static var previews: some View {
        FormItemText(label: "name", placeholder: "please input name", value: $v)
    }
}
