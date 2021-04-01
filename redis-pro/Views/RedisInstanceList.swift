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
    @EnvironmentObject var redisFavoriteModel: RedisFavoriteModel
    @State private var showFavoritesOnly = false
//    var redisModels: [RedisModel] = [RedisModel](repeating: RedisModel(), count: 0)
    @State var selectedRedisModel:String?
//    let userDefaults = UserDefaults.standard
    
    var index: Int {
        redisFavoriteModel.redisModels.firstIndex(where: { $0.id == selectedRedisModel }) ?? 0
    }
    
    var filteredRedisModel: [RedisModel] {
        redisFavoriteModel.redisModels.filter { redisModel in
            (!showFavoritesOnly || redisModel.isFavorite)
        }
    }
    
    var body: some View {
        HSplitView {
            VStack(alignment: .leading,
                   spacing: 0) {
                Text("FAVORITES")
                    .padding(.vertical, 5).padding(.horizontal, 4)
                List(selection: $selectedRedisModel) {
                    ForEach(redisFavoriteModel.redisModels) { redisModel in
                        RedisInstanceRow(redisModel: redisModel)
                            .tag(redisModel.id)
                    }
                }
                .listStyle(SidebarListStyle())
                .frame(minWidth:150)
            }
            .padding(0)
            
            
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
        }
//        .onAppear{
//            var redisModels = userDefaults.array(forKey: UserDefaulsKeys.RedisFavoriteListKey.rawValue)
//            logger.info("load redis models from user defaults: \(String(describing: redisModels))")
//            redisModels?.forEach{ (element) in
//                redisModels?.append(RedisModel(dictionary: element as! [String : Any]))
//                print("hello \(redisModels?.capacity ?? 0)  \(element)")
//            }
//        }
    }
}


struct RedisInstanceList_Previews: PreviewProvider {
    static var previews: some View {
        RedisInstanceList()
    }
}
