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
    
    let reg = #"^\d+(\.\d+)?$"#
    
    var body: some View {
//        let valueProxy = Binding<String>(
//            get: { self.value },
//            set: {
//                let result = $0.range(
//                    of: reg,
//                    options: .regularExpression
//                )
//
//                if result != nil {
//                    self.value = $0
//                } else {
//                    self.value = "0"
//                }
//            }
//        )
        
        HStack(alignment: .center) {
            if !label.isEmpty {
                FormLabel(label: label, width: labelWidth)
            }
            MDoubleField(value: $value, placeholder: placeholder)
//            MTextField(value: valueProxy)
        }
    }
}

//struct FormItemNumber_Previews: PreviewProvider {
//    @State static var v:String = "0"
//
//    static var previews: some View {
//        FormItemDouble(label: "name", value: $v)
//    }
//}
