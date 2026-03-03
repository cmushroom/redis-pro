//
//  TestView.swift
//  redis-pro
//
//  Created by chengpan on 2024/9/21.
//

import SwiftUI
import ComposableArchitecture

struct TestView: View {
//    var store: StoreOf<AppStore>
//    var tag: String = "defaultTag"
    
    let store:StoreOf<AppStore>
    init() {
        print("test view init...")
        
        let redisClient = RediStackClient(RedisModel())
        self.store =  Store(initialState: AppStore.State()) {
            AppStore()
                ._printChanges()
        } withDependencies: {
            $0.redisClient = redisClient
        }
        
        redisClient.appContextStore = store.scope(state: \.appContext, action: \.appContextAction)
    }
    
    var body: some View {
        Text("test view \(store.isConnect)")
//        Text("Window with tag: \(store.isConnect),  id: \(store.id)")
//            .frame(width: 300, height: 200)
        Button("connect", action: { store.send(.onConnect) })
        Button("disconnect", action: { store.send(.onDisconnect) })
    }
}
