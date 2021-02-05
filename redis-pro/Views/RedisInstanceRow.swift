//
//  RedisInstanceRow.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/1/25.
//

import SwiftUI

struct RedisInstanceRow: View {
    var redisModel:RedisModel
    
    var body: some View {
        HStack(alignment: .center) {
            redisModel.image
                .resizable()
                .frame(width: 24, height: 24)
                .padding(.horizontal, 0.0)
            Text(redisModel.name)
                .lineLimit(1)
                .font(.title3)
                .padding(.horizontal, 0.0)

            Spacer()
            
            if (redisModel.isFavorite) {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
            }
            
        }
    }
}

//struct RedisInstanceRow_Previews: PreviewProvider {
//    static var previews: some View {
//        RedisInstanceRow(redisInstance: RedisInstance(id: 1, name: "redis-dev", host: "r-bp167z8gzeymrrvom0pd.redis.rds.aliyuncs.com", port: 6379, db: 0, password: "zaqwedxRTY123456"
//                                                      , isFavorite: true))
//    }
//}
