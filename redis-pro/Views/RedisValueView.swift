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
        VStack {
            RedisValueHeaderView(redisKeyModel: redisKeyModel)
            Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
        }
    }
}

struct RedisValueView_Previews: PreviewProvider {
    static var previews: some View {
        RedisValueView(redisKeyModel: RedisKeyModel(id: "test", type: RedisKeyTypeEnum.STRING.rawValue))
    }
}
