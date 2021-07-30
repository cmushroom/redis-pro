//
//  LoginForm.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/1/29.
//

import SwiftUI
import NIO
import RediStack
import PromiseKit
import Logging

struct LoginForm: View {
    @Environment(\.openURL) var openURL
    @EnvironmentObject var redisInstanceModel:RedisInstanceModel
    @EnvironmentObject var globalContext:GlobalContext
    
    @ObservedObject var redisFavoriteModel: RedisFavoriteModel
    @ObservedObject var redisModel:RedisModel
    @State private var pingState:String = ""
    
    let logger = Logger(label: "redis-login")
    
    
    var saveBtnDisable: Bool {
        !redisModel.isFavorite
    }
    
    private var footer: some View {
        Section {
            Divider()
                .padding(.vertical, 8)
            VStack(alignment: .center, spacing: 10) {
                HStack(alignment: .center){
                    if !globalContext.loading {
                        Button(action: {
                            guard let url = URL(string: Constants.REPO_URL) else {
                                return
                            }
                            openURL(url)
                        }) {
                            Image(systemName: "questionmark.circle")
                                .font(.system(size: 16.0))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    MLoading(text: pingState,
                             loadingText: "Connecting...",
                             loading: globalContext.loading)
                        .help(pingState)
                    
                    Spacer()
                    
                    MButton(text: "Connect", action: onConnect, disabled: self.globalContext.loading, keyEquivalent: .return)
                        .buttonStyle(BorderedButtonStyle())
                        .keyboardShortcut(.defaultAction)
                    
                }
                
                HStack(alignment: .center){
                    MButton(text: "Add to Favorites", action: onAddRedisInstanceAction)
                    Spacer()
                    MButton(text: "Save changes", action: onSaveRedisInstanceAction)
                    Spacer()
                    MButton(text: "Test connection", action: onTestConnectionAction, disabled: self.globalContext.loading)
                }
            }
        }
    }
    
    var body: some View {
        TabView{
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 14) {
                        FormItemText(label: "Name", placeholder: "name", value: $redisModel.name, autoTrim: true)
                        FormItemText(label: "Host", placeholder: "host", value: $redisModel.host)
                        FormItemInt(label: "Port", placeholder: "port", value: $redisModel.port)
//                        FormItemText(label: "Password", value: $redisModel.password)
                        FormItemSecure(label: "Password", value: $redisModel.password)
                        FormItemInt(label: "Database", value: $redisModel.database)
                    }
                }
                
                footer
            }
            .padding(.horizontal, 18.0)
            .tabItem {
                Label("TCP/IP", systemImage: "bolt.fill")
            }
        }
        .padding(20.0)
        .frame(width: 460.0, height: 400.0)
    }
    
    
    func onTestConnectionAction() throws -> Void {
        logger.info("test connect to redis server: \(redisModel)")
        
        let _ = self.redisInstanceModel.testConnectAsync(redisModel).done({ ping in
            self.pingState = ping ? "Connect successed!" : "Connect fail! "
        })
        .catch({ error in
            self.pingState = "Connect fail, error: \(error)! "
        })
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
        let _ = redisInstanceModel.connect(redisModel:redisModel).done({r in
            logger.info("on connect to redis server successed: \(redisModel)")
            redisFavoriteModel.saveLast(redisModel: redisModel)
        })
    }
    
}

struct LoginForm_Previews: PreviewProvider {
    static var previews: some View {
        LoginForm(redisFavoriteModel: RedisFavoriteModel(), redisModel: RedisModel())
    }
}
