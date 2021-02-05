//
//  RedisModel.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/1/29.
//

import Foundation
import SwiftUI

class RedisModel:ObservableObject, Identifiable {
    @Published var id: String = ""
    @Published var name: String = "test"
    @Published var host: String = "127.0.0.1"
    @Published var port: Int = 6379
    @Published var database: Int = 0
    @Published var password: String = ""
    @Published var isFavorite: Bool = false
    
    
    var image:Image {
        Image("icon-redis")
    }
}
