//
//  RedisConfigView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/7/21.
//

import SwiftUI
import Logging
import ComposableArchitecture

struct RedisConfigView: View {
    
    @Perception.Bindable var store:StoreOf<RedisConfigStore>
    let logger = Logger(label: "redis-config-view")
    
    var body: some View {
        VStack(alignment: .leading, spacing: MTheme.V_SPACING) {
            HStack(alignment: .center , spacing: MTheme.H_SPACING) {
                
                SearchBar(placeholder: "Search config...", onCommit: {store.send(.search($0))})

                Spacer()
                MButton(text: "Rewrite", action: {store.send(.rewrite)})
                    .help("REDIS_CONFIG_REWRITE")
            }.padding(MTheme.HEADER_PADDING)
            
            NTableView(store: store.scope(state: \.tableState, action: \.tableAction))
            
            HStack(alignment: .center , spacing: MTheme.H_SPACING) {
                Spacer()
                MButton(text: "Refresh", action: {store.send(.refresh)})
            }
        }
        .sheet(isPresented: $store.editModalVisible, onDismiss: {
        }) {
            
            WithPerceptionTracking {
                ModalView("Edit Config Key: \(store.editKey)", action: {store.send(.submit)}) {
                    VStack(alignment:.leading, spacing: MTheme.V_SPACING) {
                        MTextView(text: $store.editValue)
                    }
                    .frame(minWidth:500, minHeight:300)
                }
            }
        }
        .onAppear {
            store.send(.initial)
        }
        
    }
    
}

//struct RedisConfigView_Previews: PreviewProvider {
//    static var previews: some View {
//        RedisConfigView()
//    }
//}
