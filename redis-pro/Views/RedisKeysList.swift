//
//  RedisKeysList.swift
//  redis-pro
//
//  Created by chengpan on 2021/4/4.
//

import SwiftUI

struct RedisKeysList: View {
    var redisKeyModels:[RedisKeyModel] = [RedisKeyModel](repeating: RedisKeyModel(id: UUID().uuidString, type: RedisKeyTypeEnum.HASH.rawValue), count: 1)
    @State var selectedRedisKeyId:String?
    @State var keywords:String = ""
    
    var filteredRedisKeyModel: [RedisKeyModel] {
        redisKeyModels
    }
    
    var body: some View {
        HSplitView {
            VStack(alignment: .leading,
                   spacing: 0) {
                //                                Text(selectedRedisModelId ?? "no value")
                //                Text("FAVORITES")
                //                .padding(.vertical, 4).padding(.horizontal, 4)
                RedisKeySearchRow(value: $keywords)
                    .frame(minWidth: 220)
                List(selection: $selectedRedisKeyId) {
                    ForEach(filteredRedisKeyModel) { redisKeyModel in
                        RedisKeyRow(redisKeyModel: redisKeyModel)
                            .listRowInsets(EdgeInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0)))
                    }

                }
                .listStyle(PlainListStyle())
                .frame(minWidth:220)
                .padding(.all, 0)
            }
            .padding(0)
            
            
            VStack{
                Spacer()
                HStack {
                    Spacer()
//                    LoginForm(redisModel: selectRedisModel)
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


func testData() -> [RedisKeyModel] {
    var redisKeys:[RedisKeyModel] = [RedisKeyModel](repeating: RedisKeyModel(id: UUID().uuidString, type: RedisKeyTypeEnum.STRING.rawValue), count: 50)
    redisKeys.append(RedisKeyModel(id: UUID().uuidString, type: RedisKeyTypeEnum.HASH.rawValue))
    redisKeys.append(RedisKeyModel(id: UUID().uuidString, type: RedisKeyTypeEnum.LIST.rawValue))
    redisKeys.append(RedisKeyModel(id: UUID().uuidString, type: RedisKeyTypeEnum.SET.rawValue))
    redisKeys.append(RedisKeyModel(id: UUID().uuidString, type: RedisKeyTypeEnum.ZSET.rawValue))

    
    return redisKeys
}

struct RedisKeysList_Previews: PreviewProvider {
    static var previews: some View {
        RedisKeysList(redisKeyModels: testData(), selectedRedisKeyId: "")
    }
}
