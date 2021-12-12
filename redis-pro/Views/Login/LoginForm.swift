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
    let logger = Logger(label: "redis-login")
    
    @Environment(\.openURL) var openURL
    @EnvironmentObject var redisInstanceModel:RedisInstanceModel
    @EnvironmentObject var globalContext:GlobalContext
    
    @ObservedObject var redisFavoriteModel: RedisFavoriteModel
    @Binding var redisModel:RedisModel
    
    @State private var pingState:String = ""
    
    
    var saveBtnDisable: Bool {
        !redisModel.isFavorite
    }
    var height:CGFloat {
        self.redisModel.connectionType == RedisConnectionTypeEnum.SSH.rawValue ? 500 : 380
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
//                    MButton(text: "test ssh", action: {
////                        self.redisInstanceModel.redisModel = self.redisModel
//                        self.redisInstanceModel.getClient().getSSHConnection().done { connection in
//                            let _ = connection.ping().whenSuccess { r in
//                                print("ping  \(r)")
//                            }
//                        }
//                    })
                    
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
    private var tcpTab: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 14) {
                    FormItemText(label: "Name", placeholder: "name", value: $redisModel.name, autoTrim: true)
                        .focusable()
                    FormItemText(label: "Host", placeholder: "host", value: $redisModel.host).focusable()
                    FormItemInt(label: "Port", placeholder: "port", value: $redisModel.port).focusable()
                    FormItemSecure(label: "Password", value: $redisModel.password).focusable()
                    FormItemInt(label: "Database", value: $redisModel.database).focusable()
                }
            }
            
            footer
        }
        .padding(.horizontal, 18.0)
        .tabItem {
            Text("TCP/IP")
        }.tag(RedisConnectionTypeEnum.TCP.rawValue)
    }
    private var sshTab: some View {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        FormItemText(label: "Name", placeholder: "name", value: $redisModel.name, autoTrim: true).focusable()
                        FormItemText(label: "Host", placeholder: "host", value: $redisModel.host, autoTrim: true).focusable()
                        FormItemInt(label: "Port", placeholder: "port", value: $redisModel.port).focusable()
                        FormItemSecure(label: "Password", value: $redisModel.password).focusable()
                        FormItemInt(label: "Database", value: $redisModel.database).focusable()
                    }
                }
                
                Section() {
                        Divider().padding(.vertical, 2)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            FormItemText(label: "SSH Host", placeholder: "name", value: $redisModel.sshHost, autoTrim: true).focusable()
                            FormItemInt(label: "SSH Port", placeholder: "port", value: $redisModel.sshPort).focusable()
                            FormItemText(label: "SSH User", placeholder: "host", value: $redisModel.sshUser, autoTrim: true).focusable()
                            FormItemSecure(label: "SSH Pass", value: $redisModel.sshPass).focusable()
                        }
                    }
                footer
            }
            .padding(.horizontal, 18.0)
            .tabItem {
                Label("SSH", systemImage: "bolt.fill")
            }.tag(RedisConnectionTypeEnum.SSH.rawValue)
    }
    
    var body: some View {
        TabView(selection: $redisModel.connectionType) {
            tcpTab
            sshTab
        }
        .padding(20.0)
        .frame(width: 500.0, height: height)
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
        logger.info("save favorite redis: \(redisModel)")
//        redisFavoriteModel.save(redisModel: redisModel)
        
//        redisFavoriteModel.loadAll()
    }
    
    func onConnect() throws -> Void {
        let _ = redisInstanceModel.connect(redisModel:redisModel).done({r in
            logger.info("on connect to redis server successed: \(redisModel)")
            redisFavoriteModel.saveLast(redisModel: redisModel)
        })
    }
    
}

//struct LoginForm_Previews: PreviewProvider {
//    static var previews: some View {
//        LoginForm(redisFavoriteModel: RedisFavoriteModel(), redisModel: RedisModel())
//    }
//}
