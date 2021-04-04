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
                    //                .resizable()
                    .font(.system(size: 14.0))
                //                .frame(width: 20, height: 20)
                //                .padding(.horizontal, 0.0)
                Text(redisModel.name)
                    .lineLimit(1)
                    //                .font(.title3)
                    .font(.system(size: 12.0))
                    .padding(0.0)
                Spacer()
            }
            .padding(.vertical, 4)
            Rectangle().frame(height: 1)
                .padding(.horizontal, 0).foregroundColor(Color.gray)
        }
    }
}

struct RedisQuickRow_Previews: PreviewProvider {
    static var previews: some View {
        RedisQuickRow(redisModel: RedisModel(name: "QUICK CONNECT"))
    }
}
