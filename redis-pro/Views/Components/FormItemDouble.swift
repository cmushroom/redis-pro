//
//  FormItemNumber.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/5/7.
//

import SwiftUI


struct FormItemDouble: View {
    var label:String
    var labelWidth:CGFloat = 80
    var placeholder:String?
    @Binding var value:Double
    
    var body: some View {
        HStack(alignment: .center) {
            if !label.isEmpty {
                FormLabel(label: label, width: labelWidth)
            }
            MDoubleField(value: $value, placeholder: placeholder)
        }
    }
}

struct FormItemNumber_Previews: PreviewProvider {
    @State static var v:Double = 0
    
    static var previews: some View {
        FormItemDouble(label: "name", value: $v)
    }
}
