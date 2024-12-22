//
//  LoginForm.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/1/29.
//

import SwiftUI
import Logging
import ComposableArchitecture

struct LoginForm: View {
    let logger = Logger(label: "redis-login")
    
    @Environment(\.openURL) var openURL
    
    @Perception.Bindable var store:StoreOf<LoginStore>
    
    var footer: some View {
        Section {
            Divider().padding(.vertical, 8)
            VStack(alignment: .center, spacing: 10) {
                HStack(alignment: .center){
                    if !store.loading {
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
                    
                        Text(store.pingR)
                        Text("hello pingR")
                        Text("r: \(store.pingR)|| \(store.loading)")
                    WithPerceptionTracking {
                        MLoading(text: store.pingR,
                                 loadingText: "Connecting...",
                                 loading: store.loading)
                        .help(store.pingR)
                    }
                    
                    Spacer()
                    
                    MButton(text: "Connect",
                            action: { store.send(.connect) },
                            disabled: store.loading,
                            keyEquivalent: .return )
                    .buttonStyle(BorderedButtonStyle())
                    .keyboardShortcut(.defaultAction)
                    
                }
                
                HStack(alignment: .center){
                    MButton(text: "Add to Favorites", action: {
                        store.send(.add)
                    })
                    Spacer()
                    MButton(text: "Save changes", action: {
                        store.send(.save)
                    })
                    Spacer()
                    MButton(text: "Test connection", action: {
                        store.send(.testConnect)
                    }, disabled: store.loading)
                }
            }
        }
    }
    
    var tcpView: some View {
        
            Form {
                VStack {
                    Section {
                        VStack(alignment: .leading, spacing: 14) {
                            FormItemText(label: "Name", placeholder: "name", value: $store.name)
                            FormItemText(label: "Host", placeholder: "host", value: $store.host)
                            FormItemInt(label: "Port", placeholder: "port", value: $store.port)
                            FormItemText(label: "User", placeholder: "default", value: $store.username)
                            FormItemPassword(label: "Password", value: $store.password)
                            FormItemInt(label: "Database", value: $store.database)
                        }
                    }
                    
                    footer
                }
            }
            .padding(.horizontal, 18.0)
        
    }
    
    var sshTab: some View {
        Form {
            VStack {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        FormItemText(label: "Name", placeholder: "name", value: $store.name)
                        FormItemText(label: "Host", placeholder: "host", value: $store.host)
                        FormItemInt(label: "Port", placeholder: "port", value: $store.port)
                        FormItemText(label: "User", placeholder: "default", value: $store.username)
                        FormItemPassword(label: "Password", value: $store.password)
                        FormItemInt(label: "Database", value: $store.database)
                    }
                }
                
                Divider().padding(.vertical, 2)
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        FormItemText(label: "SSH Host", placeholder: "name", value: $store.sshHost)
                        FormItemInt(label: "SSH Port", placeholder: "port", value: $store.sshPort)
                        FormItemText(label: "SSH User", placeholder: "host", value: $store.sshUser)
                        FormItemPassword(label: "SSH Pass", value: $store.sshPass)
                    }
                }
                
                footer
            }
        }
        .padding(.horizontal, 18.0)
        
    }
    
    var body: some View {
        WithPerceptionTracking {
            TabView(selection: $store.connectionType) {
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
            .frame(width: 500.0, height: store.height)
        }
    }
}
