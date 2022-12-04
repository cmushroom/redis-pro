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

    var store:Store<FavoriteState, FavoriteAction>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            HSplitView {
                VStack(alignment: .leading,
                       spacing: 0) {
                    
                    NTableView(
                        store: store.scope(state: \.tableState, action: FavoriteAction.tableAction)
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
                LoginForm(store: store.scope(state: \.loginState, action: FavoriteAction.loginAction))
                    .frame(minWidth: 700, maxWidth: .infinity, minHeight: 520, maxHeight: .infinity)
            }
        }
    }
    
    func onLoad(_ viewStore:ViewStore<FavoriteState, FavoriteAction>) {
        viewStore.send(.getAll)
        viewStore.send(.initDefaultSelection)
    }
}


//struct RedisInstanceList_Previews: PreviewProvider {
//    private static var redisFavoriteModel: RedisFavoriteModel = RedisFavoriteModel()
//    static var previews: some View {
//        RedisListView()
//            .environmentObject(redisFavoriteModel)
//            .onAppear{
//                redisFavoriteModel.loadAll()
//            }
//
//    }
//}
