//
//  HomeView.swift
//  redis-pro
//
//  Created by chengpan on 2021/4/4.
//

import SwiftUI

struct HomeView: View {
    var redisInstanceModel:RedisInstanceModel
    
    var body: some View {
        RedisKeysListView(redisInstanceModel:redisInstanceModel)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(redisInstanceModel: RedisInstanceModel(redisModel: RedisModel()))
    }
}
