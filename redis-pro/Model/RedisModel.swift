//
//  RedisModel.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/1/29.
//

import Foundation
import SwiftUI

class RedisModel:NSObject, ObservableObject, Identifiable {
    @Published var id: String = UUID().uuidString
    @objc @Published var name: String = "New Favorite"
    @Published var host: String = "127.0.0.1"
    @Published var port: Int = 6379
    @Published var database: Int = 0
    @Published var password: String = ""
    @Published var isFavorite: Bool = false
    @Published var ping: Bool = false
    
    var image:Image  = Image("icon-redis")
    
    var dictionary: [String: Any] {
        return ["id": id,
                "name": name,
                "host": host,
                "port": port,
                "database": database,
                "password": password
        ]
    }
    
    override init() {
    }
    
    init(name: String) {
        self.name = name
    }
    
    init(password: String) {
        self.password = password
    }
    
    init(dictionary: [String: Any]) {
        self.id = dictionary["id"] as! String
        self.name = dictionary["name"] as! String
        self.host = dictionary["host"] as! String
        self.port = dictionary["port"] as! Int
        self.database = dictionary["database"] as! Int
        self.password = dictionary["password"] as! String
    }
    
    
    override var description: String {
        return "RedisModel:[id:\(id), name:\(name), host:\(host), port:\(port), password:\(password), database:\(database)]"
    }
}
