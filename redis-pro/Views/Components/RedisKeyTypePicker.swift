//
//  RedisKeyTypePicker.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/7.
//

import SwiftUI

struct RedisKeyTypePicker: View {
    var body: some View {
        Picker("", selection: $pageSize) {
            ForEach(0..<filteredRedisKeyModel.count)
            Text("50").tag(50)
            Text("100").tag(100)
            Text("200").tag(200)
            Text("500").tag(500)
        }
        .frame(width: 70)
        Text("Keys:123")
            .font(.footnote)
    }
}

struct RedisKeyTypePicker_Previews: PreviewProvider {
    static var previews: some View {
        RedisKeyTypePicker()
    }
}
