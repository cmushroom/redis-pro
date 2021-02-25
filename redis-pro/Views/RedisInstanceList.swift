//
//  RedisInstanceList.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/1/25.
//

import SwiftUI
import Logging

func onAppear() {
    print("list on appear。。。")
}

struct RedisInstanceList: View {
    @State private var showFavoritesOnly = false
    var redisModels: [RedisModel] = [RedisModel](repeating: RedisModel(), count: 5)
    var test: [Any]?
    @State var selectedRedisModel:String?
    let userDefaults = UserDefaults.standard
    
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
            .frame(minWidth: 500, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
        }.onAppear{
            logger.info("load redis models from user defaults")
            let a = userDefaults.array(forKey: UserDefaulsKeys.RedisFavoriteListKey.rawValue)
            logger.info("\(a?.description ?? "hello")")
        }
    }
}


struct RedisInstanceList_Previews: PreviewProvider {
    static var previews: some View {
        RedisInstanceList(redisModels: [RedisModel()])
    }
}
