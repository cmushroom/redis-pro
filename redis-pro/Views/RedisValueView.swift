//
//  RedisValueView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/7.
//

import SwiftUI

struct RedisValueView: View {
    @Binding var redisKeyModel:RedisKeyModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RedisValueHeaderView(redisKeyModel: $redisKeyModel)
                .padding(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
            Rectangle().frame(height: 1)
                .padding(.horizontal, 0).foregroundColor(Color.gray.opacity(0.1))
            
            RedisValueEditView(redisKeyModel: $redisKeyModel)
        }
    }
}

struct RedisValueView_Previews: PreviewProvider {
    @State private static var redisKeyModel = RedisKeyModel("test", type: RedisKeyTypeEnum.STRING.rawValue)
    static var previews: some View {
        RedisValueView(redisKeyModel: $redisKeyModel)
    }
}
