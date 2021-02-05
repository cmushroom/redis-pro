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
    
    
    func testConnectionAction() throws -> Void {
        logger.info("test connection, name: \(redisModel.name), host: \(redisModel.host), port: \(redisModel.port), password: \(redisModel.password)")
        loading = true
        defer {
            loading = false
        }
        let redisInstanceModel = RedisInstanceModel(redisModel: redisModel)
        
        self.pong = try redisInstanceModel.ping()
    }
    
    func saveRedisInstanceAction()  throws -> Void {
        
        logger.info("save redis to favorite id: \(redisModel.id), name: \(redisModel.name), host: \(redisModel.host), port: \(redisModel.port), password: \(redisModel.password)")
        
        let defaults = UserDefaults.standard
        var savedRedisList:[RedisModel] = defaults.object(forKey: UserDefaulsKeys.RedisFavoriteListKey.rawValue) as? [RedisModel] ?? [RedisModel]()
        
        
        if(redisModel.id.isEmpty) {
            redisModel.id = UUID().uuidString
            savedRedisList.append(redisModel)
        } else {
            if let index = savedRedisList.firstIndex(where: { (e) -> Bool in
                return e.id == redisModel.id
            }) {
                savedRedisList[index] = redisModel
            } else {
                savedRedisList.append(redisModel)
            }
        }
        
        
        
        defaults.set(savedRedisList, forKey: UserDefaulsKeys.RedisFavoriteListKey.rawValue)
    }
    
    func signIn() throws -> Void {
        logger.info("test connection, name: \(redisModel.name), host: \(redisModel.host), port: \(redisModel.port), password: \(redisModel.password)")
        
        //        self.pong = try redisInstanceModel.ping()
        //        let dict = ["1":2, "2":"two", "3": nil] as [String: Any?]
        //
        //        print(String(data: try! JSONSerialization.data(withJSONObject: redisInstanceModel, options: .prettyPrinted), encoding: .utf8)!)
        //
        //        let json = JSON(dict)
        //        let representation = json.rawString()
        //        print("json \(representation)")
        //        print("button click \(name), \(host), \(port), \(redisInstanceModel)")
    }
    
    var body: some View {
        HStack {
            RedisInstanceList()
        }
    }
}

struct Login_Previews: PreviewProvider {
    static var previews: some View {
        Login()
    }
}
