//
//  RedisKeyTypePicker.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/7.
//

import SwiftUI

struct RedisKeyTypePicker: View {
    var label:String = ""
    @Binding var value:String
    var disabled:Bool = false
    
    var body: some View {
        Picker("\(label):", selection: $value) {
            ForEach(RedisKeyTypeEnum.allCases.filter{$0 != RedisKeyTypeEnum.NONE}, id: \.self) { item in
                Text(item.rawValue).tag(item.rawValue)
            }
        }
        .disabled(disabled)
        .frame(width: 120)
    }
}

struct RedisKeyTypePicker_Previews: PreviewProvider {
    @State static var value = RedisKeyTypeEnum.STRING.rawValue
    static var previews: some View {
        RedisKeyTypePicker(value: $value)
    }
}
