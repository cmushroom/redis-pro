//
//  Login.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/1/25.
//

import SwiftUI
import NIO
import RediStack
import Logging
import ComposableArchitecture


struct LoginView: View {
    let logger = Logger(label: "login-view")
    
    var store: StoreOf<AppStore>
    
    var body: some View {
        RedisListView(store: store.scope(state: \.favoriteState, action: \.favoriteAction))
    }
}
