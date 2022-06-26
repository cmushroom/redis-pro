//
//  RedisModel.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/1/29.
//

import Foundation
import SwiftUI

class RedisModel: NSObject, ObservableObject, Identifiable {
    @objc var id: String = UUID().uuidString
    @objc @Published var name: String = "New Favorite"
    @Published var host: String = "127.0.0.1"
    @Published var port: Int = 6379
    @Published var database: Int = 0
    var user: String = "default"
    @Published var password: String = ""
    @Published var isFavorite: Bool = false
    @Published var ping: Bool = false
    @Published var connectionType:String = "tcp"
    
    // ssh
    @Published var sshHost:String = ""
    @Published var sshPort:Int = 22
    @Published var sshUser:String = ""
    @Published var sshPass:String = ""
    
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
    
    
    override init() {
    }
    
    convenience init(name: String) {
        self.init()
        self.name = name
    }
    
    convenience init(password: String) {
        self.init()
        self.password = password
    }
    
    convenience init(dictionary: [String: Any]) {
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
    
    static func == (a: RedisModel, b: RedisModel) -> Bool {
        return a === b || a.id == b.id
    }
    
    override var description: String {
        return "RedisModel:[id:\(id), name:\(name), host:\(host), port:\(port), password:\(password), database:\(database), type:\(connectionType), sshHost:\(sshHost), sshPort:\(sshPort),sshUser:\(sshUser)]"
    }
}
