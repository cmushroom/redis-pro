//
//  RedisInstanceList.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/1/25.
//

import SwiftUI
import Logging
import ComposableArchitecture

struct RedisListView: View {
    let logger = Logger(label: "redis-login")

    var store:StoreOf<FavoriteStore>
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) {viewStore in
            HSplitView {
                VStack(alignment: .leading,
                       spacing: 0) {
                    
                    NTableView(
                        store: store.scope(state: \.tableState, action: FavoriteStore.Action.tableAction)
                    )
                    
                    // footer
                    HStack(alignment: .center) {
                        MIcon(icon: "plus", fontSize: 13, action: {
                            viewStore.send(.addNew)
                        })
                        MIcon(icon: "minus", fontSize: 13, disabled: viewStore.tableState.selectIndex < 0, action: {
                            viewStore.send(.deleteConfirm(viewStore.tableState.selectIndex))
                        })
                    }
                    .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                }
                       .padding(0)
                       .frame(minWidth:200)
                       .layoutPriority(0)
                       .onAppear{
                           onLoad(viewStore)
                       }
                LoginForm(store: store.scope(state: \.loginState, action: FavoriteStore.Action.loginAction))
                    .frame(minWidth: 800, maxWidth: .infinity, minHeight: 520, maxHeight: .infinity)
            }
        }
    }
    
    func onLoad(_ viewStore:ViewStore<FavoriteStore.State, FavoriteStore.Action>) {
        viewStore.send(.getAll)
        viewStore.send(.initDefaultSelection)
    }
}
