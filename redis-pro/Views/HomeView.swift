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
    let logger = Logger(label: "home-view")
    var store:StoreOf<AppStore>

    var body: some View {
        WithViewStore(self.store, observe: { $0.title }) { viewStore in
//        WithViewStore(store.scope(state: \.title)) {viewStore in
            
            RedisKeysListView(store)
                .onAppear {
                    logger.info("redis pro home view init complete")
                    viewStore.send(.initial)
                }
                .onDisappear {
                    logger.info("redis pro home view destroy...")
                    viewStore.send(.onClose)
                }
            // 设置window标题
            .navigationTitle(viewStore.state)
            
        }
    }
}

//struct HomeView_Previews: PreviewProvider {
//    static var previews: some View {
//        HomeView()
//    }
//}
