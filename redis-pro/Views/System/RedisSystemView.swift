//
//  RedisSystemView.swift
//  redis-pro
//
//  Created by chengpan on 2022/6/4.
//

import SwiftUI
import Logging
import ComposableArchitecture

struct RedisSystemView: View {
    var store:StoreOf<RedisSystemStore>
    
    var body: some View {
        WithViewStore(self.store, observe: { $0.systemView }) {viewStore in
    
            if viewStore.state == RedisSystemViewTypeEnum.REDIS_INFO {
                RedisInfoView(store: store.scope(state: \.redisInfoState, action: RedisSystemStore.Action.redisInfoAction))
            }  else if viewStore.state == RedisSystemViewTypeEnum.CLIENT_LIST {
                ClientsListView(store: store.scope(state: \.clientListState, action: RedisSystemStore.Action.clientListAction))
            } else if viewStore.state == RedisSystemViewTypeEnum.SLOW_LOG {
                SlowLogView(store: store.scope(state: \.slowLogState, action: RedisSystemStore.Action.slowLogAction))
            } else if viewStore.state == RedisSystemViewTypeEnum.REDIS_CONFIG {
                RedisConfigView(store: store.scope(state: \.redisConfigState, action: RedisSystemStore.Action.redisConfigAction))
            } else if viewStore.state == RedisSystemViewTypeEnum.LUA {
                LuaView(store: store.scope(state: \.luaState, action: RedisSystemStore.Action.luaAction))
            } else {
                EmptyView()
            }
        }
    }
}

//struct RedisSystemView_Previews: PreviewProvider {
//    static var previews: some View {
//        RedisSystemView()
//    }
//}
