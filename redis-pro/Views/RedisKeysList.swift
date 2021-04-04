//
//  RedisKeysList.swift
//  redis-pro
//
//  Created by chengpan on 2021/4/4.
//

import SwiftUI

struct RedisKeysList: View {
    var redisKeyModels:[RedisKeyModel]
    @State var selectedRedisKeyId:String
    
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
                List(selection: $selectedRedisKeyId) {
                    ForEach(filteredRedisModel) { redisKeyModel in
                        RedisKeyRow(redisKeyModel: redisKeyModel)
                            .listRowInsets(EdgeInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0)))
                    }
                    
                }
                .listStyle(PlainListStyle())
                .frame(minWidth:150)
                .padding(.all, 0)
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

struct RedisKeysList_Previews: PreviewProvider {
    static var previews: some View {
        RedisKeysList()
    }
}
