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
    
    var store:StoreOf<RedisConfigStore>
    let logger = Logger(label: "redis-config-view")
    
    var body: some View {
        
        WithViewStore(self.store, observe: { $0 }) {viewStore in
            VStack(alignment: .leading, spacing: MTheme.V_SPACING) {
                HStack(alignment: .center , spacing: MTheme.H_SPACING) {
                    
                    SearchBar(placeholder: "Search config...", onCommit: {viewStore.send(.search($0))})

                    Spacer()
                    MButton(text: "Rewrite", action: {viewStore.send(.rewrite)})
                        .help("REDIS_CONFIG_REWRITE")
                }.padding(MTheme.HEADER_PADDING)
                
                NTableView(store: store.scope(state: \.tableState, action: RedisConfigStore.Action.tableAction))
                
                HStack(alignment: .center , spacing: MTheme.H_SPACING) {
                    Spacer()
                    MButton(text: "Refresh", action: {viewStore.send(.refresh)})
                }
            }
            .sheet(isPresented: viewStore.binding(\.$editModalVisible), onDismiss: {
            }) {
                ModalView("Edit Config Key: \(viewStore.editKey)", action: {viewStore.send(.submit)}) {
                    VStack(alignment:.leading, spacing: MTheme.V_SPACING) {
                        MTextView(text: viewStore.binding(\.$editValue))
                    }
                    .frame(minWidth:500, minHeight:300)
                }
            }
            .onAppear {
                viewStore.send(.initial)
            }
        }
    }
    
}

//struct RedisConfigView_Previews: PreviewProvider {
//    static var previews: some View {
//        RedisConfigView()
//    }
//}
