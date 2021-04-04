//
//  FormItemInt.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/1/28.
//

import SwiftUI

struct FormItemInt: View {
    var label:String
    var placeholder:String?
    @Binding var value:Int
    
    
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
            FormLabel(label: label)
            TextField(placeholder ?? label, text: valueProxy)
            
        }
    }
}

struct FormItemInt_Previews: PreviewProvider {
    @State static var v:Int = 0
    
    static var previews: some View {
        FormItemInt(label: "name", value: $v)
    }
}
