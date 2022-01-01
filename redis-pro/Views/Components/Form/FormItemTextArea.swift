//
//  FormItemTextArea.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/29.
//

import SwiftUI

struct FormItemTextArea: View {
    var label: String = ""
    var labelWidth:CGFloat = 80
    var placeholder: String?
    var required:Bool = false
    @Binding var value: String
    var disabled:Bool = false
    
    var body: some View {
        HStack(alignment: .top) {
            if !label.isEmpty {
                FormLabel(label: label, width: labelWidth, required: required)
                    .padding(EdgeInsets(top: 4, leading: 0, bottom: 0, trailing: 0))
            }
            
            MTextEditor(text: $value)
        }
    }
}

struct FormItemTextArea_Previews: PreviewProvider {
    @State static var v: String = "";
    static var previews: some View {
        FormItemTextArea(label: "name", placeholder: "please input name", value: $v)
    }
}
