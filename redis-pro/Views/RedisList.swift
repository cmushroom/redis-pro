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

struct RedisList: View {
    @EnvironmentObject var redisFavoriteModel: RedisFavoriteModel
    @State private var showFavoritesOnly = false
    //    var redisModels: [RedisModel] = [RedisModel](repeating: RedisModel(), count: 0)
    @State var selectedRedisModelId: String?
    
    var quickRedisModel:[RedisModel] = [RedisModel](repeating: RedisModel(name: "QUICK CONNECT"), count: 1)
    
    var selectRedisModel: RedisModel {
        redisFavoriteModel.redisModels.first(where: { $0.id == selectedRedisModelId }) ?? RedisModel()
    }
    
    var filteredRedisModel: [RedisModel] {
        redisFavoriteModel.redisModels
    }
    
    var body: some View {
        HSplitView {
            VStack(alignment: .leading,
                   spacing: 0) {
                //                                Text(selectedRedisModelId ?? "no value")
                //                Text("FAVORITES")
                //                .padding(.vertical, 4).padding(.horizontal, 4)
                List(selection: $selectedRedisModelId) {
                    
                    
                    ForEach(quickRedisModel) { redisModel in
                        
                        RedisQuickRow(redisModel: redisModel)
                            .listRowInsets(EdgeInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0)))
                    }
                    
//                    Rectangle().frame(height: 1)
//                        .padding(0).foregroundColor(Color.gray)
//                        .listRowInsets(EdgeInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0)))
                    
                    Section(header: Text("FAVORITES")) {
                        ForEach(filteredRedisModel) { redisModel in
                            RedisRow(redisModel: redisModel)
                        }
                    }
                    .collapsible(false)
                    
                }
                .listStyle(PlainListStyle())
                .frame(minWidth:150)
                .padding(.all, 0)
                //                .border(Color.black, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
            }
            .padding(0)
            
            
            VStack{
                Spacer()
                HStack {
                    Spacer()
                    LoginForm(redisModel: selectRedisModel)
                    Spacer()
                }
                Spacer()
            }
            .frame(minWidth: 500, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
        }
        .onAppear{
        }
    }
}


struct RedisInstanceList_Previews: PreviewProvider {
    private static var redisFavoriteModel: RedisFavoriteModel = RedisFavoriteModel()
    static var previews: some View {
        RedisList()
            .environmentObject(redisFavoriteModel)
            .onAppear{
                redisFavoriteModel.loadAll()
            }
        
    }
}
