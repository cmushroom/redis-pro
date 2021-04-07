//
//  RedisKeyTypePicker.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/7.
//

import SwiftUI

struct RedisKeyTypePicker: View {
    var label:String = ""
    @State var value:String = RedisKeyTypeEnum.STRING.rawValue
    
    var body: some View {
        Picker("\(label):", selection: $value) {
            ForEach(RedisKeyTypeEnum.allCases, id: \.self) { item in
                Text(item.rawValue).tag(item.rawValue)
            }
        }
        .frame(width: 120)
    }
}

struct RedisKeyTypePicker_Previews: PreviewProvider {
    static var previews: some View {
        RedisKeyTypePicker()
    }
}
