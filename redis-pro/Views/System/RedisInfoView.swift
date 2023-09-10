//
//  RedisInfoView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/6/10.
//

import SwiftUI
import Logging
import ComposableArchitecture

struct RedisInfoView: View {
    var store:StoreOf<RedisInfoStore>
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) {viewStore in
            VStack(alignment: .leading, spacing: MTheme.V_SPACING) {
                TabView(selection: viewStore.binding(get: \.section, send: RedisInfoStore.Action.setTab)) {
                    ForEach(viewStore.redisInfoModels.indices, id:\.self) { index in
                        NTableView(store: store.scope(state: \.tableState, action: RedisInfoStore.Action.tableAction))
                            .tabItem {
                                Text(viewStore.redisInfoModels[index].section)
                            }
                            .tag(viewStore.redisInfoModels[index].section)
                    }
                }
                .frame(minWidth: 500, minHeight: 600)
                
                HStack(alignment: .center , spacing: MTheme.H_SPACING) {
                    Spacer()
                    MButton(text: "Reset State", action: {viewStore.send(.resetState)})
                    MButton(text: "Refresh", action: {viewStore.send(.refresh)})
                }
            }
            .onAppear {
                viewStore.send(.initial)
            }
        }
    }
}

//struct RedisInfoView_Previews: PreviewProvider {
//
//    static var redisInstanceModel:RedisInstanceModel = RedisInstanceModel(redisModel: RedisModel(password: ""))
//
//    static var previews: some View {
//        RedisInfoView().environmentObject(redisInstanceModel)
//    }
//
//}
