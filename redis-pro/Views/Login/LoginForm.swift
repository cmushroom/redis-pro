//
//  LoginForm.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/1/29.
//

import SwiftUI
import NIO
import RediStack
import Logging

struct LoginForm: View {
    @EnvironmentObject var redisInstanceModel:RedisInstanceModel
    @StateObject var redisFavoriteModel: RedisFavoriteModel
    @StateObject var redisModel:RedisModel
    @State private var loading:Bool = false
    @State private var pong:Bool = false
    @State private var isJump:Bool = false
    
    let logger = Logger(label: "redis-login")
    
    var saveBtnDisable: Bool {
        !redisModel.isFavorite
    }
    
    var body: some View {
        TabView{
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 14) {
                        FormItemText(label: "Name", placeholder: "name", value: $redisModel.name)
                        FormItemText(label: "Host", placeholder: "host", value: $redisModel.host)
                        FormItemInt(label: "Port", placeholder: "port", value: $redisModel.port)
                        FormItemText(label: "Password", value: $redisModel.password)
                        FormItemInt(label: "Database", value: $redisModel.database)
                    }
                }
                
                Section {
                    Divider()
                        .padding(.vertical, 8)
                    HStack(alignment: .center){
                        Button(action: {
                            if let url = URL(string: "https://github.com/cmushroom/redis-pro") {
                                NSWorkspace.shared.open(url)
                            }
                        }) {
                            Image(systemName: "questionmark.circle")
                                .font(.system(size: 18.0))
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if (loading) {
                            ProgressView().progressViewStyle(CircularProgressViewStyle()).scaleEffect(CGSize(width: 0.5, height: 0.5))
                        }
                        
                        Text(pong ? "Connect successed!" : " ")
                            .font(.body)
                            .multilineTextAlignment(.leading)
                            .lineLimit(1)
                            .frame(height: 10.0)
                        
                        Spacer()
                        //                            NavigationLink(
                        //                                "", destination: HomeView(redisInstanceModel: RedisInstanceModel(redisModel: RedisModel())),
                        //                                isActive: $isJump
                        //                            ).frame(width:0)
                        MButton(text: "Connect", action: onConnect)
                            .buttonStyle(BorderedButtonStyle())
                            .keyboardShortcut(.defaultAction)
                        
                    }
//                    .frame(height: 40.0)
                    HStack(alignment: .center){
                        MButton(text: "Add to Favorites", action: onAddRedisInstanceAction)
                        Spacer()
                        MButton(text: "Save changes", action: onSaveRedisInstanceAction)
                        Spacer()
                        MButton(text: "Test connection", action: onTestConnectionAction)
                    }
                }
            }
            .padding(.horizontal, 18.0)
            .tabItem {
                Label("TCP/IP", systemImage: "bolt.fill")
            }
            
            //                Text("Another Tab")
            //                    .tabItem {
            //                        Image(systemName: "2.square.fill")
            //                        Text("Second")
            //                    }
        }
        .padding(20.0)
        .frame(width: 420.0, height: 340.0)
    }
    
    
    func onTestConnectionAction() throws -> Void {
        logger.info("test connection, name: \(redisModel.name), host: \(redisModel.host), port: \(redisModel.port), password: \(redisModel.password)")
        loading = true
        defer {
            loading = false
        }
        let redisInstanceModel = RedisInstanceModel(redisModel: redisModel)
        
        self.pong = try redisInstanceModel.ping()
    }
    
    func onAddRedisInstanceAction()  throws -> Void {
        redisModel.id = UUID().uuidString
        logger.info("add redis to favorite, id: \(redisModel.id), name: \(redisModel.name), host: \(redisModel.host), port: \(redisModel.port), password: \(redisModel.password)")
        
        let defaults = UserDefaults.standard
        var savedRedisList:[Dictionary] = defaults.object(forKey: UserDefaulsKeysEnum.RedisFavoriteListKey.rawValue) as? [Dictionary<String, Any>] ?? [Dictionary]()
        logger.info("get user favorite redis: \(savedRedisList)")
        
        savedRedisList.append(redisModel.dictionary)
        
        print("save list \(savedRedisList)")
        
        defaults.set(savedRedisList, forKey: UserDefaulsKeysEnum.RedisFavoriteListKey.rawValue)
        logger.info("add redis to favorite complete")
        
        redisFavoriteModel.loadAll()
    }
    
    func onSaveRedisInstanceAction()  throws -> Void {
        
        logger.info("save redis to favorite, id: \(redisModel.id), name: \(redisModel.name), host: \(redisModel.host), port: \(redisModel.port), password: \(redisModel.password)")
        
        let defaults = UserDefaults.standard
        var savedRedisList:[Dictionary] = defaults.object(forKey: UserDefaulsKeysEnum.RedisFavoriteListKey.rawValue) as? [Dictionary<String, Any>] ?? [Dictionary]()
        logger.info("get user favorite redis: \(savedRedisList)")
        
        if let index = savedRedisList.firstIndex(where: { (e) -> Bool in
            return e["id"] as! String == redisModel.id
        }) {
            savedRedisList[index] = redisModel.dictionary
        } else {
            savedRedisList.append(redisModel.dictionary)
        }
        
        print("save list \(savedRedisList)")
        
        defaults.set(savedRedisList, forKey: UserDefaulsKeysEnum.RedisFavoriteListKey.rawValue)
        logger.info("save redis to favorite complete")
        
        redisFavoriteModel.loadAll()
    }
    
    func onConnect() throws -> Void {
        logger.info("test connection, name: \(redisModel.name), host: \(redisModel.host), port: \(redisModel.port), password: \(redisModel.password)")
        //        self.isJump = true
//        redisInstanceModel.redisModel = redisModel
//        do {
//        try! redisInstanceModel.ping()
//        } catch let e{
//            throw e
//        }
        redisInstanceModel.isConnect.toggle()
        print("redis instance is connect: \(redisInstanceModel.isConnect)")
    }
    
}

struct LoginForm_Previews: PreviewProvider {
    static var previews: some View {
        LoginForm(redisFavoriteModel: RedisFavoriteModel(), redisModel: RedisModel())
    }
}
