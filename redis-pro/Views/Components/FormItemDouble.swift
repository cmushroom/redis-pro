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
    var formatter = DoubleFormatter()
    
    var body: some View {
        let valueProxy = Binding<String>(
            get: { formatter.string(for: self.value) ?? "" },
            set: {
                if let value = NumberFormatter().number(from: $0) {
                    self.value = value.doubleValue
                }
            }
        )
        
        HStack(alignment: .center) {
            if !label.isEmpty {
                FormLabel(label: label, width: labelWidth)
            }
//            MDoubleField(value: valueProxy, placeholder: placeholder)
            MTextField(value: valueProxy)
        }
    }
}

struct FormItemNumber_Previews: PreviewProvider {
    @State static var v:Double = 0
    
    static var previews: some View {
        FormItemDouble(label: "name", value: $v)
    }
}
