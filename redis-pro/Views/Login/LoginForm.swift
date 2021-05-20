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
    @EnvironmentObject var globalContext:GlobalContext
    
    @State private var loading:Bool = true
    
    @ObservedObject var redisFavoriteModel: RedisFavoriteModel
    @ObservedObject var redisModel:RedisModel
    
    
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
                        
                        //                        Text(redisModel.ping ? "Connect successed!" : " ")
                        //                            .font(.body)
                        //                            .frame(height: 10.0)
                        MLoading(text: redisModel.ping ? "Connect successed!" : " ",
                                 loadingText: "Connecting...",
                                 loading: loading)
                        
                        Spacer()
                        
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
        logger.info("test connect to redis server: \(redisModel)")
        
        self.loading =  true
        
        defer {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.loading =  false
                // Put your code which should be executed with a delay here
            }
            
        }
        
        let ping = try redisInstanceModel.testConnect(redisModel:redisModel)
        if !ping {
            throw BizError(message: "test connection redis error!")
        }
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
        
        redisFavoriteModel.save(redisModel: redisModel)
        
        redisFavoriteModel.loadAll()
    }
    
    func onConnect() throws -> Void {
        self.loading =  true
        
        defer {
            self.loading =  false
        }
        
        try redisInstanceModel.connect(redisModel:redisModel)
        redisFavoriteModel.saveLast(redisModel: redisModel)
        logger.info("on connect to redis server: \(redisModel)")
    }
    
}

struct LoginForm_Previews: PreviewProvider {
    static var previews: some View {
        LoginForm(redisFavoriteModel: RedisFavoriteModel(), redisModel: RedisModel())
    }
}
