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
    
    let store:Store<LoginState, LoginAction>
   
    private func footer(_ viewStore: ViewStore<LoginState, LoginAction>) -> some View {
        Section {
            Divider()
                .padding(.vertical, 8)
            VStack(alignment: .center, spacing: 10) {
                HStack(alignment: .center){
                    if !viewStore.loading {
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
    
    private func tcpTab(_ viewStore: ViewStore<LoginState, LoginAction>) -> some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 14) {
                    FormItemText(label: "Name", placeholder: "name", value: viewStore.binding(\.$name))
                    FormItemText(label: "Host", placeholder: "host", value: viewStore.binding(\.$host))
                    FormItemInt(label: "Port", placeholder: "port", value: viewStore.binding(\.$port))
                    FormItemPassword(label: "Password", value: viewStore.binding(\.$password))
                    FormItemInt(label: "Database", value: viewStore.binding(\.$database))
                }
            }
            
            footer(viewStore)
        }
        .padding(.horizontal, 18.0)
        .tabItem {
            Text("TCP/IP")
        }.tag(RedisConnectionTypeEnum.TCP.rawValue)
    }
    
    private func sshTab(_ viewStore: ViewStore<LoginState, LoginAction>) -> some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    FormItemText(label: "Name", placeholder: "name", value: viewStore.binding(\.$name))
                    FormItemText(label: "Host", placeholder: "host", value: viewStore.binding(\.$host))
                    FormItemInt(label: "Port", placeholder: "port", value: viewStore.binding(\.$port))
                    FormItemPassword(label: "Password", value: viewStore.binding(\.$password))
                    FormItemInt(label: "Database", value: viewStore.binding(\.$database))
                }
            }
            
            Section() {
                    Divider().padding(.vertical, 2)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        FormItemText(label: "SSH Host", placeholder: "name", value: viewStore.binding(\.$sshHost))
                        FormItemInt(label: "SSH Port", placeholder: "port", value: viewStore.binding(\.$sshPort))
                        FormItemText(label: "SSH User", placeholder: "host", value: viewStore.binding(\.$sshUser))
                        FormItemPassword(label: "SSH Pass", value: viewStore.binding(\.$sshPass))
                    }
                }
            footer(viewStore)
        }
        .padding(.horizontal, 18.0)
        .tabItem {
            Label("SSH", systemImage: "bolt.fill")
        }.tag(RedisConnectionTypeEnum.SSH.rawValue)
    }
    
    var body: some View {
        WithViewStore(store) { viewStore in
            TabView(selection: viewStore.binding(\.$connectionType)) {
                tcpTab(viewStore)
                sshTab(viewStore)
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
