//
//  LoginForm.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/1/29.
//

import SwiftUI
import Logging
import Cocoa
import ComposableArchitecture

struct LoginForm: View {
    let logger = Logger(label: "redis-login")
    
    @Environment(\.openURL) var openURL
    
    let store:StoreOf<LoginStore>
    var viewStore1: ViewStoreOf<LoginStore>
    
    struct ViewState: Equatable {
       @BindingViewState var name: String
       @BindingViewState var host: String
       @BindingViewState var port: Int
       @BindingViewState var username: String
       @BindingViewState var password: String
       @BindingViewState var database: Int
       @BindingViewState var sshHost: String
       @BindingViewState var sshPort: Int
       @BindingViewState var sshUser: String
       @BindingViewState var sshPass: String
        
        init(bindingViewStore: BindingViewStore<LoginStore.State>) {
              self._name = bindingViewStore.$name
              self._host = bindingViewStore.$host
              self._port = bindingViewStore.$port
              self._username = bindingViewStore.$username
              self._password = bindingViewStore.$password
              self._database = bindingViewStore.$database
              self._sshHost = bindingViewStore.$sshHost
              self._sshPort = bindingViewStore.$sshPort
              self._sshUser = bindingViewStore.$sshUser
              self._sshPass = bindingViewStore.$sshPass
        }
     }
    
    init(store: StoreOf<LoginStore>) {
        self.store = store
        self.viewStore1 = ViewStore(store, observe: {$0})
    }
   
    var footer: some View {
        WithViewStore(self.store, observe: {$0} ) { viewStore in
            Section {
                Divider()
                    .padding(.vertical, 8)
                VStack(alignment: .center, spacing: 10) {
                    HStack(alignment: .center){
                        if !viewStore.loading {
                            Button(action: {
                                guard let url = URL(string: Const.REPO_URL) else {
                                    return
                                }
                                openURL(url)
                            }) {
                                Image(systemName: "questionmark.circle")
                                    .font(.system(size: 16.0))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        MLoading(text: viewStore.pingR,
                                 loadingText: "Connecting...",
                                 loading: viewStore.loading)
                        .help(viewStore.pingR)
                        
                        Spacer()
                        
                        MButton(text: "Connect"
                                , action: {
                            viewStore.send(.connect)
                        }
                                , disabled: viewStore.loading, keyEquivalent: .return)
                        .buttonStyle(BorderedButtonStyle())
                        .keyboardShortcut(.defaultAction)
                        
                    }
                    
                    HStack(alignment: .center){
                        MButton(text: "Add to Favorites", action: {
                            viewStore.send(.add)
                        })
                        Spacer()
                        MButton(text: "Save changes", action: {
                            viewStore.send(.save)
                        })
                        Spacer()
                        MButton(text: "Test connection", action: {
                            viewStore.send(.testConnect)
                        }, disabled: viewStore.loading)
                    }
                }
            }
        }
    }
    
    var tcpView: some View {
        WithViewStore(self.store, observe: ViewState.init) { viewStore in
            Form {
                VStack {
                    Section {
                        VStack(alignment: .leading, spacing: 14) {
                            FormItemText(label: "Name", placeholder: "name", value: viewStore.$name)
                            FormItemText(label: "Host", placeholder: "host", value: viewStore.$host)
                            FormItemInt(label: "Port", placeholder: "port", value: viewStore.$port)
                            FormItemText(label: "User", placeholder: "default", value: viewStore.$username)
                            FormItemPassword(label: "Password", value: viewStore.$password)
                            FormItemInt(label: "Database", value: viewStore.$database)
                        }
                    }
                    
                    footer
                }
            }
            .padding(.horizontal, 18.0)
        }
    }
    
//    private func tcpTab() -> some View {
//        WithViewStore(self.store, observe: ViewState.init) { viewStore in
//            Form {
//                Section {
//                    VStack(alignment: .leading, spacing: 14) {
//                        FormItemText(label: "Name", placeholder: "name", value: viewStore.$name)
//                        FormItemText(label: "Host", placeholder: "host", value: viewStore.$host)
//                        FormItemInt(label: "Port", placeholder: "port", value: viewStore.$port)
//                        FormItemText(label: "User", placeholder: "default", value: viewStore.$username)
//                        FormItemPassword(label: "Password", value: viewStore.$password)
//                        FormItemInt(label: "Database", value: viewStore.$database)
//                    }
//                }
//
//                footer(viewStore)
//            }
//            .padding(.horizontal, 18.0)
//            .tabItem {
//                Text("TCP/IP")
//            }
//            .tag(RedisConnectionTypeEnum.TCP.rawValue)
//        }
//    }
//
    
    var sshTab: some View {
        WithViewStore(self.store, observe: ViewState.init) { viewStore in
            Form {
                VStack {
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            FormItemText(label: "Name", placeholder: "name", value: viewStore.$name)
                            FormItemText(label: "Host", placeholder: "host", value: viewStore.$host)
                            FormItemInt(label: "Port", placeholder: "port", value: viewStore.$port)
                            FormItemText(label: "User", placeholder: "default", value: viewStore.$username)
                            FormItemPassword(label: "Password", value: viewStore.$password)
                            FormItemInt(label: "Database", value: viewStore.$database)
                        }
                    }
                    
                    Divider().padding(.vertical, 2)
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            FormItemText(label: "SSH Host", placeholder: "name", value: viewStore.$sshHost)
                            FormItemInt(label: "SSH Port", placeholder: "port", value: viewStore.$sshPort)
                            FormItemText(label: "SSH User", placeholder: "host", value: viewStore.$sshUser)
                            FormItemPassword(label: "SSH Pass", value: viewStore.$sshPass)
                        }
                    }
                    
                    footer
                }
            }
            .padding(.horizontal, 18.0)
        }
    }
//    private func sshTab(_ viewStore: ViewStoreOf<LoginStore>) -> some View {
//        Form {
//            Section {
//                VStack(alignment: .leading, spacing: 12) {
//                    FormItemText(label: "Name", placeholder: "name", value: viewStore.$name)
//                    FormItemText(label: "Host", placeholder: "host", value: viewStore.$host)
//                    FormItemInt(label: "Port", placeholder: "port", value: viewStore.$port)
//                    FormItemText(label: "User", placeholder: "default", value: viewStore.$username)
//                    FormItemPassword(label: "Password", value: viewStore.$password)
//                    FormItemInt(label: "Database", value: viewStore.$database)
//                }
//            }
//
//            Section() {
//                    Divider().padding(.vertical, 2)
//
//                    VStack(alignment: .leading, spacing: 12) {
//                        FormItemText(label: "SSH Host", placeholder: "name", value: viewStore.$sshHost)
//                        FormItemInt(label: "SSH Port", placeholder: "port", value: viewStore.$sshPort)
//                        FormItemText(label: "SSH User", placeholder: "host", value: viewStore.$sshUser)
//                        FormItemPassword(label: "SSH Pass", value: viewStore.$sshPass)
//                    }
//                }
//            footer(viewStore)
//        }
//        .padding(.horizontal, 18.0)
//        .tabItem {
//            Label("SSH", systemImage: "bolt.fill")
//        }.tag(RedisConnectionTypeEnum.SSH.rawValue)
//    }
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            TabView(selection: viewStore.$connectionType) {
                // tcp
                tcpView
                .tabItem {
                    Text("TCP/IP")
                }.tag(RedisConnectionTypeEnum.TCP.rawValue)
                
                // ssh
                sshTab
                .tabItem {
                    Label("SSH", systemImage: "bolt.fill")
                }.tag(RedisConnectionTypeEnum.SSH.rawValue)
            }
            .padding(20.0)
            .frame(width: 500.0, height: viewStore.height)
        }
    }
    
}

//struct LoginForm_Previews: PreviewProvider {
//    static var previews: some View {
//        LoginForm(redisFavoriteModel: RedisFavoriteModel(), redisModel: RedisModel())
//    }
//}
