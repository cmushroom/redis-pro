//
//  RedisInfoView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/6/10.
//

import SwiftUI

struct RedisInfoView: View {
    @State var redisInfoModels:[RedisInfoModel] = [RedisInfoModel]()
    
    var body: some View {
        TabView{
            ForEach(redisInfoModels, id: \.section) { item in
                Text(item.section)
                    .tabItem {
                        Text(item.section)
                    }
            }
        }.frame(width: 500, height: 600, alignment: .center)
        .onAppear {
            
        }
    }
    
    
    func buildRedisInfoModel() {
        redisInfoModels = [RedisInfoModel]()
        redisInfoModels.append(RedisInfoModel(section: "# Server", infos: [("redis_version", "6.2.1"), ("redis_version", "6.2.1"), ("redis_version", "6.2.1")]))
        redisInfoModels.append(RedisInfoModel(section: "# Clients", infos: [("redis_version", "6.2.1"), ("redis_version", "6.2.1"), ("redis_version", "6.2.1")]))
        redisInfoModels.append(RedisInfoModel(section: "# Memory", infos: [("redis_version", "6.2.1"), ("redis_version", "6.2.1"), ("redis_version", "6.2.1")]))
        redisInfoModels.append(RedisInfoModel(section: "# Stats", infos: [("redis_version", "6.2.1"), ("redis_version", "6.2.1"), ("redis_version", "6.2.1")]))
    }
}

struct RedisInfoView_Previews: PreviewProvider {
    
    static var previews: some View {
        RedisInfoView()
    }
    
}
