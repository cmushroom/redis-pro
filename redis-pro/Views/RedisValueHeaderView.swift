//
//  RedisValueHeaderView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/7.
//

import SwiftUI

struct RedisValueHeaderView: View {
    @State var redisKeyModel:RedisKeyModel
    
    var body: some View {
        HStack {
            FormItemText(label: "Key", value: $redisKeyModel.id)
            FormItemText(label: "Type", value: $redisKeyModel.type)
        }
    }
}

struct RedisValueHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        RedisValueHeaderView(redisKeyModel: RedisKeyModel(id: "test", type: RedisKeyTypeEnum.STRING.rawValue))
    }
}
