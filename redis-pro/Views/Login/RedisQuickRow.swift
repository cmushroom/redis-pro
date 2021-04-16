//
//  RedisQuickRow.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/2.
//

import SwiftUI

struct RedisQuickRow: View {
    var redisModel:RedisModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 14.0))
                Text(redisModel.name)
                    .lineLimit(1)
                    .font(.system(size: 12.0))
                    .padding(0.0)
                Spacer()
            }
            .padding(.vertical, 4)
            Rectangle().frame(height: 1)
                .padding(.horizontal, 0).foregroundColor(Color.gray.opacity(0.6))
        }
    }
}

struct RedisQuickRow_Previews: PreviewProvider {
    static var previews: some View {
        RedisQuickRow(redisModel: RedisModel(name: "QUICK CONNECT"))
    }
}
