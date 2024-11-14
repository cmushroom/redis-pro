//
//  TestView.swift
//  redis-pro
//
//  Created by chengpan on 2024/9/21.
//

import SwiftUI
import ComposableArchitecture

struct TestView: View {
    var store: StoreOf<AppStore>
    var tag: String = "defaultTag"
    
    var body: some View {
        Text("Window with tag: \(store.isConnect),  id: \(store.id)")
            .frame(width: 300, height: 200)
        Button("connect", action: { store.send(.onConnect) })
        Button("disconnect", action: { store.send(.onDisconnect) })
    }
}
