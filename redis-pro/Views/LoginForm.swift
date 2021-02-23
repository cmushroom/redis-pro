//
//  LoginForm.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/1/29.
//

import SwiftUI
import NIO
import RediStack
import SwiftyJSON
import Logging

struct LoginForm: View {
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
            TabView{
                Form {
                    VStack(alignment: .leading) {
                        FormItemText(label: "Name", placeholder: "name", value: $redisModel.name)
                        FormItemText(label: "Host", placeholder: "host", value: $redisModel.host)
                        FormItemInt(label: "Port", placeholder: "port", value: $redisModel.port)
                        FormItemText(label: "Password", value: $redisModel.password)
                        FormItemInt(label: "Database", value: $redisModel.database)
                    }
                    Section {
                        Divider()
                        HStack(alignment: .center){
                            Button(action: {
                                if let url = URL(string: "https://www.apple.com") {
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
                            MButton(text: "Connect", action: signIn)
                                .buttonStyle(BorderedButtonStyle())
                                .keyboardShortcut(.defaultAction)
                        }
                        .frame(height: 40.0)
                        HStack(alignment: .center){
                            MButton(text: "Add to Favorites", action: saveRedisInstanceAction)
                            Spacer()
                            MButton(text: "Save changes", action: signIn)
                            Spacer()
                            MButton(text: "Test connection", action: testConnectionAction)
                        }
                    }
                }
                .padding(.horizontal, 8.0)
                .tabItem {
                    Label("TCP/IP", systemImage: "bolt.fill")
                }
                
                Text("Another Tab")
                    .tabItem {
                        Image(systemName: "2.square.fill")
                        Text("Second")
                    }
                Text("The Last Tab")
                    .tabItem {
                        Image(systemName: "3.square.fill")
                        Text("Third")
                    }
            }
            .padding(20.0)
            .frame(width: 500.0, height: 400)
        }
        .padding(20.0)
        .border(Color.blue, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
    }
}

struct LoginForm_Previews: PreviewProvider {
    static var previews: some View {
        LoginForm()
    }
}
