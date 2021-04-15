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
                .padding(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
            Rectangle().frame(height: 1)
                .padding(.horizontal, 0).foregroundColor(Color.gray.opacity(0.1))
            
            RedisValueEditView(redisKeyModel: redisKeyModel, value: "12342412")
        }
        .padding(2)
    }
}

struct RedisValueView_Previews: PreviewProvider {
    static var previews: some View {
        RedisValueView(redisKeyModel: RedisKeyModel(id: "test", type: RedisKeyTypeEnum.STRING.rawValue))
    }
}
