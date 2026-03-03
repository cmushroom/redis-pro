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
    
    // let store:StoreOf<AppStore>
    // 每个窗口独立持有自己的 Store
    private var store:StoreOf<AppStore>
    
    
    init(store:StoreOf<AppStore>) {
        logger.info("index view init...")
        self.store = store
    }
    
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
        }.onAppear {
            logger.info("index view on appear inner...")
        }
    }
}
