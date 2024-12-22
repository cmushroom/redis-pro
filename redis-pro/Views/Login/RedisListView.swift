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
        WithPerceptionTracking {
            HSplitView {
                VStack(alignment: .leading, spacing: 0) {
                    // left navigation
                    NTableView(
                        store: store.scope(state: \.tableState, action: \.tableAction)
                    )
                    
                    // footer
                    HStack(alignment: .center) {
                        MIcon(icon: "plus", fontSize: 13, action: {
                            store.send(.addNew)
                        })
                        MIcon(icon: "minus", fontSize: 13, disabled: store.tableState.selectIndex < 0, action: {
                            store.send(.deleteConfirm(store.tableState.selectIndex))
                        })
                    }
                    .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                }
                .padding(0)
                .frame(minWidth:200)
                .layoutPriority(0)
                .onAppear{
                    onLoad()
                }
                LoginForm(store: store.scope(state: \.loginState, action: \.loginAction))
                    .frame(minWidth: 800, maxWidth: .infinity, minHeight: 520, maxHeight: .infinity)
            }
        }
    }
    
    func onLoad() {
        self.store.send(.getAll)
        self.store.send(.initDefaultSelection)
    }
}
