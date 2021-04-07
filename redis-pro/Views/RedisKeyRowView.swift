//
//  RedisKeyRow.swift
//  redis-pro
//
//  Created by chengpan on 2021/4/4.
//

import SwiftUI

struct RedisKeyRowView: View {
    var index:Int = 0
    var redisKeyModel:RedisKeyModel
    
    var body: some View {
        HStack(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/, spacing: 2) {
//            Text("\(index)")
//                .multilineTextAlignment(.leading)
//                .lineLimit(1)
//                .font(.caption)
            Tag(name: redisKeyModel.type)
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                .frame(width: 40, alignment: .leading)
//            Text(redisKeyModel.type).foregroundColor(.orange)
//                .multilineTextAlignment(.leading)
//                .lineLimit(1)
//                .font(.system(size: 12))
//                .padding(0.0)
                
            Text(redisKeyModel.id)
                .multilineTextAlignment(.leading)
                .lineLimit(1)
                .font(.system(size: 12))
                .padding(0.0)
            Spacer()
        }
    }
}

struct RedisKeyRow_Previews: PreviewProvider {
    static var previews: some View {
        RedisKeyRowView(redisKeyModel: RedisKeyModel(id: UUID().uuidString, type: RedisKeyTypeEnum.STRING.rawValue))
    }
}
