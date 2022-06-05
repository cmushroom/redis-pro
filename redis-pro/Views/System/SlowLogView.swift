//
//  SlowLogView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/7/14.
//

import SwiftUI
import Logging
import ComposableArchitecture

struct SlowLogView: View {
    var store:Store<SlowLogState, SlowLogAction>
    let logger = Logger(label: "slow-log-view")
    
    var body: some View {
        WithViewStore(store) { viewStore in
            VStack(alignment: .leading, spacing: MTheme.V_SPACING) {
                // header
                HStack(alignment: .center, spacing: MTheme.H_SPACING) {
                    FormItemInt(label: "Slower Than(us)", labelWidth: 120, value: viewStore.binding(\.$slowerThan), suffix: "square.and.pencil", onCommit: {viewStore.send(.setSlowerThan)})
                        .help("REDIS_SLOW_LOG_SLOWER_THAN")
                        .frame(width: 320)
                    FormItemInt(label: "Max Len", value: viewStore.binding(\.$maxLen), suffix: "square.and.pencil", onCommit: {viewStore.send(.setMaxLen)})
                        .help("REDIS_SLOW_LOG_MAX_LEN")
                        .frame(width: 200)
                    
                    FormItemInt(label: "Size", value: viewStore.binding(\.$size), suffix: "square.and.pencil", onCommit: {viewStore.send(.setSize)})
                        .help("REDIS_SLOW_LOG_SIZE")
                        .frame(width: 200)
                    
                    Spacer()
                    MButton(text: "Reset", action: {viewStore.send(.reset)})
                        .help("REDIS_SLOW_LOG_RESET")
                }
                
                NTableView(store: store.scope(state: \.tableState, action: SlowLogAction.tableAction))
                
                // footer
                HStack(alignment: .center, spacing: MTheme.H_SPACING_L) {
                    Spacer()
                    Text("Total: \(viewStore.total)")
                        .font(.system(size: 12))
                        .help("REDIS_SLOW_LOG_TOTAL")
                    Text("Current: \(viewStore.tableState.datasource.count)")
                        .font(.system(size: 12))
                        .help("REDIS_SLOW_LOG_SIZE")
                    IconButton(icon: "arrow.clockwise", name: "Refresh", action: {viewStore.send(.refresh)})
                }
                .padding(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
            }.onAppear {
                viewStore.send(.initial)
            }
        }
    }
}

//struct SlowLogView_Previews: PreviewProvider {
//    static var redisInstanceModel:RedisInstanceModel = RedisInstanceModel(redisModel: RedisModel())
//
//    static var previews: some View {
//        SlowLogView()
//            .environmentObject(redisInstanceModel)
//    }
//}
