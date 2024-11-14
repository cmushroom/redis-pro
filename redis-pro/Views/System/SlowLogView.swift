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
    @Perception.Bindable var store:StoreOf<SlowLogStore>
    let logger = Logger(label: "slow-log-view")
    
    var body: some View {
    
            VStack(alignment: .leading, spacing: MTheme.V_SPACING) {
                // header
                HStack(alignment: .center, spacing: MTheme.H_SPACING) {
                    FormItemInt(label: "Slower Than(us)", labelWidth: 120, value: $store.slowerThan, suffix: "square.and.pencil", onCommit: {store.send(.setSlowerThan)})
                        .help("REDIS_SLOW_LOG_SLOWER_THAN")
                        .frame(width: 320)
                    FormItemInt(label: "Max Len", value: $store.maxLen, suffix: "square.and.pencil", onCommit: {store.send(.setMaxLen)})
                        .help("REDIS_SLOW_LOG_MAX_LEN")
                        .frame(width: 200)
                    
                    FormItemInt(label: "Size", value: $store.size, suffix: "square.and.pencil", onCommit: {store.send(.setSize)})
                        .help("REDIS_SLOW_LOG_SIZE")
                        .frame(width: 200)
                    
                    Spacer()
                    MButton(text: "Reset", action: {store.send(.reset)})
                        .help("REDIS_SLOW_LOG_RESET")
                }
                
                NTableView(store: store.scope(state: \.tableState, action: \.tableAction))
                
                // footer
                HStack(alignment: .center, spacing: MTheme.H_SPACING_L) {
                    Spacer()
                    Text("Total: \(store.total)")
                        .font(.system(size: 12))
                        .help("REDIS_SLOW_LOG_TOTAL")
                    Text("Current: \(store.tableState.datasource.count)")
                        .font(.system(size: 12))
                        .help("REDIS_SLOW_LOG_SIZE")
                    IconButton(icon: "arrow.clockwise", name: "Refresh", action: {store.send(.refresh)})
                }
                .padding(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
            }.onAppear {
                store.send(.initial)
            }
        
    }
}
