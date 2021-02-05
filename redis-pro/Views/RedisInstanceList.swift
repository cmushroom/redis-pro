//
//  RedisInstanceList.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/1/25.
//

import SwiftUI

struct RedisInstanceList: View {
    @State private var showFavoritesOnly = false
    var redisModels: [RedisModel] = [RedisModel](repeating: RedisModel(), count: 5)
    @State var selectedRedisModel:String?
    
    var index: Int {
        redisModels.firstIndex(where: { $0.id == selectedRedisModel }) ?? 0
    }
    
    var filteredRedisModel: [RedisModel] {
        redisModels.filter { redisModel in
            (!showFavoritesOnly || redisModel.isFavorite)
        }
    }
    
    var body: some View {
        NavigationView {
            List(selection: $selectedRedisModel) {
                ForEach(filteredRedisModel) { redisModel in
                    RedisInstanceRow(redisModel: redisModel)
                        .tag(redisModel.id)
                }
            }
            .frame(minWidth: 120)
            
            LoginForm()
        }
    }
}

struct RedisInstanceList_Previews: PreviewProvider {
    static var previews: some View {
        RedisInstanceList(redisModels: [RedisModel()])
    }
}
