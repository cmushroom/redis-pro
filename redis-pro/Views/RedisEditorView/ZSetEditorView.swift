//
//  ZSetEditorView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/5/7.
//

import SwiftUI
import Logging
import ComposableArchitecture

struct ZSetEditorView: View {
    
    var store:StoreOf<ZSetValueStore>
    var keyObjectStore: StoreOf<KeyObjectStore>
    let logger = Logger(label: "redis-set-editor")
    
    
    init(store: StoreOf<ValueStore>) {
        self.store = store.scope(state: \.zsetValueState, action: ValueStore.Action.zsetValueAction)
        self.keyObjectStore = store.scope(state: \.keyObjectState, action: ValueStore.Action.keyObjectAction)
    }
    
    var body: some View {

        WithViewStore(self.store, observe: { $0 }) { viewStore in
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center , spacing: 4) {
                IconButton(icon: "plus", name: "Add", action: {viewStore.send(.addNew)})
                IconButton(icon: "trash", name: "Delete", disabled: viewStore.tableState.selectIndex < 0, action: {viewStore.send(.deleteConfirm(viewStore.tableState.selectIndex))})

                SearchBar(placeholder: "Search element...", onCommit: {viewStore.send(.search($0))})
                PageBar(store: store.scope(state: \.pageState, action: ZSetValueStore.Action.pageAction))
            }
            .padding(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
            
            NTableView(store: store.scope(state: \.tableState, action: ZSetValueStore.Action.tableAction))

            // footer
            HStack(alignment: .center, spacing: 4) {
                KeyObjectBar(store: keyObjectStore)
                Spacer()
                IconButton(icon: "arrow.clockwise", name: "Refresh", action: {viewStore.send(.refresh)})
            }
            .padding(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
        }
        .sheet(isPresented: viewStore.binding(\.$editModalVisible), onDismiss: {
        }) {
            ModalView("Edit zset element", action: {viewStore.send(.submit)}) {
                VStack(alignment:.leading, spacing: 8) {
                    FormItemDouble(label: "Score", placeholder: "score", value: viewStore.binding(\.$editScore))
                    FormItemTextArea(label: "Value", placeholder: "value", value: viewStore.binding(\.$editValue))
                }
            }
        }
        }
    }
    
}

//struct ZSetEditorView_Previews: PreviewProvider {
//    static var redisKeyModel:RedisKeyModel = RedisKeyModel(key: "tes", type: "string")
//    static var previews: some View {
//        ZSetEditorView(redisKeyModel: redisKeyModel)
//    }
//}
