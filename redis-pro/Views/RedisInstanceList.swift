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
        HSplitView {
            List(selection: $selectedRedisModel) {
                ForEach(filteredRedisModel) { redisModel in
                    RedisInstanceRow(redisModel: redisModel)
                        .tag(redisModel.id)
                }
            }
            .listStyle(SidebarListStyle())
            .frame(minWidth:150)
            
            VStack{
                Spacer()
                HStack {
                    Spacer()
                    LoginForm()
                    Spacer()
                }
                Spacer()
            }
            .frame(minWidth: 800, maxWidth: .infinity, minHeight: 600, maxHeight: .infinity)
        }
    }
}

struct RedisInstanceList_Previews: PreviewProvider {
    static var previews: some View {
        RedisInstanceList(redisModels: [RedisModel()])
    }
}
