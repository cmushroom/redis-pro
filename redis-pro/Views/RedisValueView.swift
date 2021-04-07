//
//  RedisValueView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/7.
//

import SwiftUI

struct RedisValueView: View {
    var redisKeyModel:RedisKeyModel
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RedisValueHeaderView(redisKeyModel: redisKeyModel)
                .padding(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
            Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
        }
        .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
    }
}

struct RedisValueView_Previews: PreviewProvider {
    static var previews: some View {
        RedisValueView(redisKeyModel: RedisKeyModel(id: "test", type: RedisKeyTypeEnum.STRING.rawValue))
    }
}
