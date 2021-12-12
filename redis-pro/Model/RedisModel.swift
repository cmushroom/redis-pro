//
//  RedisModel.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/1/29.
//

import Foundation
import SwiftUI

struct RedisModel: Identifiable {
    var id: String = UUID().uuidString
    var name: String = "New Favorite"
    var host: String = "127.0.0.1"
    var port: Int = 6379
    var database: Int = 0
    var password: String = ""
    var isFavorite: Bool = false
    var ping: Bool = false
    var connectionType:String = "tcp"
    
    // ssh
    var sshHost:String = ""
    var sshPort:Int = 22
    var sshUser:String = ""
    var sshPass:String = ""
    
    var image:Image  = Image("icon-redis")
    
    var dictionary: [String: Any] {
        return ["id": id,
                "name": name,
                "host": host,
                "port": port,
                "database": database,
                "password": password,
                "connectionType": connectionType,
                "sshHost": sshHost,
                "sshPort": sshPort,
                "sshUser": sshUser,
                "sshPass": sshPass,
        ]
    }
    
    
    init() {
    }
    
    init(name: String) {
        self.init()
        self.name = name
    }
    
    init(password: String) {
        self.init()
        self.password = password
    }
    
    init(dictionary: [String: Any]) {
        self.init()
        
        self.id = dictionary["id"] as! String
        self.name = dictionary["name"] as! String
        self.host = dictionary["host"] as! String
        self.port = dictionary["port"] as! Int
        self.database = dictionary["database"] as! Int
        self.password = dictionary["password"] as! String
        // ssh
        let connectionType:String = dictionary["connectionType"] as? String ?? RedisConnectionTypeEnum.TCP.rawValue
        self.connectionType = connectionType
        
        if (connectionType == RedisConnectionTypeEnum.SSH.rawValue) {
            self.sshHost = dictionary["sshHost"] as? String ?? ""
            self.sshPort = dictionary["sshPort"] as? Int ?? 22
            self.sshUser = dictionary["sshUser"] as? String ?? ""
            self.sshPass = dictionary["sshPass"] as? String ?? ""
        }
    }
    
    static func ==(a: RedisModel, b: RedisModel) -> Bool {
        return a.id == b.id
    }
    
    var description: String {
        return "RedisModel:[id:\(id), name:\(name), host:\(host), port:\(port), password:\(password), database:\(database), type:\(connectionType), sshHost:\(sshHost), sshPort:\(sshPort),sshUser:\(sshUser)]"
    }
}

class NSRedisModel:NSObject, ObservableObject, Identifiable {
    @Published var id: String = UUID().uuidString
    @objc @Published var name: String = "New Favorite"
    
    override init() {
    }
    
    init( _ redisModel: RedisModel) {
        super.init()
        self.id = redisModel.id
        self.name = redisModel.name
    }
    
}
