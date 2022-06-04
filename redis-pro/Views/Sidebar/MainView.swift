//
// 主视图
//  MainView.swift
//  redis-pro
//
//  Created by chengpanwang on 2022/5/6.
//

import SwiftUI
import Logging
import ComposableArchitecture


struct MainView: View {
    var store: Store<ValueState, ValueAction>
    
    var body: some View {
        WithViewStore(store.scope(state: \.mainViewType)) {viewStore in
            VStack(alignment: .leading, spacing: 0){
                if viewStore.state == MainViewTypeEnum.EDITOR {
                    RedisValueView(store: store)
                } else if viewStore.state == MainViewTypeEnum.REDIS_INFO {
                    RedisInfoView()
                }  else if viewStore.state == MainViewTypeEnum.CLIENT_LIST {
                    ClientsListView()
                } else if viewStore.state == MainViewTypeEnum.SLOW_LOG {
                    SlowLogView()
                } else if viewStore.state == MainViewTypeEnum.REDIS_CONFIG {
                    RedisConfigView()
                } else {
                    EmptyView()
                }
                
                Spacer()
            }
            .padding(4)
            .frame(minWidth: 600, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
            .layoutPriority(1)
        }
    }
}
