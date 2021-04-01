//
//  Login.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/1/25.
//

import SwiftUI
import NIO
import RediStack
import SwiftyJSON
import Logging

let logger = Logger(label: "login")

struct Login: View {
    @ObservedObject var redisModel:RedisModel = RedisModel()
    @State private var loading:Bool = false
    @State private var pong:Bool = false
    var redisModels: [RedisModel] = [RedisModel](repeating: RedisModel(), count: 0)
    var redisFavoriteModel: RedisFavoriteModel = RedisFavoriteModel()
    
    var body: some View {
        HStack {
            RedisList()
        }
    }
}

struct Login_Previews: PreviewProvider {
    static var previews: some View {
        Login()
    }
}
