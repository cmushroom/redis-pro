//
//  IndexView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/8.
//

import SwiftUI
import Logging
import ComposableArchitecture

struct IndexView: View {
    let logger = Logger(label: "index-view")
    
    let store:StoreOf<AppStore>
    
    var body: some View {
        
        WithPerceptionTracking {
            ZStack {
                VStack {
                    if (store.isConnect) {
                        HomeView(store: store)
                    } else {
                        LoginView(store: store)
                    }
                }
                
//                LoadingView(store: store.scope(state: \.appContext, action: \.appContextAction))
            }
        }
    }
}
