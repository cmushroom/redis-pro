//
//  RedisValueHeaderView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/7.
//

import SwiftUI

struct RedisValueHeaderView: View {
    @ObservedObject var redisKeyModel:RedisKeyModel
    
    var body: some View {
        HStack(alignment: .center, spacing: 6) {
            FormItemText(label: "Key", labelWidth: 40, required: true, value: $redisKeyModel.key)
            RedisKeyTypePicker(label: "Type", value: redisKeyModel.type)
            FormItemInt(label: "TTL(s)", value: $redisKeyModel.ttl)
                .frame(width: 160)
            Spacer()
        }
    }
}

struct RedisValueHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        RedisValueHeaderView(redisKeyModel: RedisKeyModel(key: "test", type: RedisKeyTypeEnum.STRING.rawValue))
    }
}
