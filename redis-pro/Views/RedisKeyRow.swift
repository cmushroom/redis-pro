//
//  RedisKeyRow.swift
//  redis-pro
//
//  Created by chengpan on 2021/4/4.
//

import SwiftUI

struct RedisKeyRow: View {
    var redisKeyModel:RedisKeyModel
    
    var body: some View {
        HStack {
            Tag(name: redisKeyModel.type)
                .padding(EdgeInsets(top: 0, leading: 2, bottom: 0, trailing: 2))
                .frame(width: 40, alignment: .leading)
            Text(redisKeyModel.id)
                .lineLimit(1)
                .font(.title3)
                .padding(0.0)
            Spacer()
        }
    }
}

struct RedisKeyRow_Previews: PreviewProvider {
    static var previews: some View {
        RedisKeyRow(redisKeyModel: RedisKeyModel(id: UUID().uuidString, type: RedisKeyTypeEnum.STRING.rawValue))
    }
}
