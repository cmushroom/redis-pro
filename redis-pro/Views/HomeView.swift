//
//  HomeView.swift
//  redis-pro
//
//  Created by chengpan on 2021/4/4.
//

import SwiftUI
import Logging
import ComposableArchitecture

struct HomeView: View {
    var store:Store<AppState, AppAction>
    let logger = Logger(label: "home-view")
    
    init(_ store:Store<AppState, AppAction>) {
        logger.info("home view init...")
        self.store = store
    }
    
    var body: some View {
        WithViewStore(store) {viewStore in
            
            RedisKeysListView(store)
                .onAppear {
                    logger.info("redis pro home view init complete")
                }
                .onDisappear {
                    logger.info("redis pro home view destroy...")
                    viewStore.send(.onClose)
                }
            
        }
    }
}

//struct HomeView_Previews: PreviewProvider {
//    static var previews: some View {
//        HomeView()
//    }
//}
