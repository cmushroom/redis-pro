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

struct LoginView: View {
    let logger = Logger(label: "login-view")
    
    var body: some View {
        RedisListView()
            .onDisappear {
                logger.info("redis pro login view destroy...")
            }
            .onAppear {
                logger.info("redis pro login view init complete")
            }
    }
}

struct Login_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
