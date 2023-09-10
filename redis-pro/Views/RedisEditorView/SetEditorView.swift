//
//  ListEditorView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/30.
//

import SwiftUI
import Logging
import ComposableArchitecture

struct SetEditorView: View {
    
    var store:StoreOf<SetValueStore>
    var keyObjectStore: StoreOf<KeyObjectStore>
    let logger = Logger(label: "redis-set-editor")
    
    init(store: StoreOf<ValueStore>) {
        self.store = store.scope(state: \.setValueState, action: ValueStore.Action.setValueAction)
        self.keyObjectStore = store.scope(state: \.keyObjectState, action: ValueStore.Action.keyObjectAction)
    }
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center , spacing: 4) {
                IconButton(icon: "plus", name: "Add", action: {viewStore.send(.addNew)})
                IconButton(icon: "trash", name: "Delete", disabled: viewStore.tableState.selectIndex < 0, action: {viewStore.send(.deleteConfirm(viewStore.tableState.selectIndex))})

                SearchBar(placeholder: "Search element...", onCommit: {viewStore.send(.search($0))})
                PageBar(store: store.scope(state: \.pageState, action: SetValueStore.Action.pageAction))
            }
            .padding(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
            
            NTableView(store: store.scope(state: \.tableState, action: SetValueStore.Action.tableAction))

            
            // footer
            HStack(alignment: .center, spacing: MTheme.H_SPACING) {
                KeyObjectBar(store: keyObjectStore)
                Spacer()
                IconButton(icon: "arrow.clockwise", name: "Refresh", action: {viewStore.send(.refresh)})
            }
            .padding(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
        }
        .sheet(isPresented: viewStore.$editModalVisible, onDismiss: {
        }) {
            ModalView("Edit set element", action: {viewStore.send(.submit)}) {
                VStack(alignment:.leading, spacing: MTheme.V_SPACING) {
                    FormItemTextArea(placeholder: "value", value: viewStore.$editValue)
                }
            }
        }
        }
    }
}

//struct SetEditorView_Previews: PreviewProvider {
//    static var redisKeyModel:RedisKeyModel = RedisKeyModel(key: "tes", type: "string")
//    static var previews: some View {
//        SetEditorView(redisKeyModel: redisKeyModel)
//    }
//}
