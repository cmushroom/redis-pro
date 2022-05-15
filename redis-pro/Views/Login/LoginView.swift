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
    let store: Store<AppState, AppAction>
    
    init(store: Store<AppState, AppAction>) {
        logger.info("login view init...")
        self.store = store
    }
    
    var body: some View {
        RedisListView(store: store.scope(state: \.favoriteState, action: AppAction.favoriteAction))
            .onDisappear {
                logger.info("redis pro login view destroy...")
            }
            .onAppear {
                logger.info("redis pro login view init complete")
            }
    }
}

//struct Login_Previews: PreviewProvider {
//    static var previews: some View {
//        LoginView()
//    }
//}
