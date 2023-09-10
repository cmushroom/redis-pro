//
//  ListEditorView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/30.
//

import SwiftUI
import Logging
import ComposableArchitecture

struct ListEditorView: View {
    
    var store:StoreOf<ListValueStore>
    var keyObjectStore: StoreOf<KeyObjectStore>
    let logger = Logger(label: "redis-list-editor")
    
    init(store: StoreOf<ValueStore>) {
        self.store = store.scope(state: \.listValueState, action: ValueStore.Action.listValueAction)
        self.keyObjectStore = store.scope(state: \.keyObjectState, action: ValueStore.Action.keyObjectAction)
    }
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center , spacing: 4) {
                IconButton(icon: "plus", name: "Add head", action: { viewStore.send(.addNew(-1))})
                IconButton(icon: "plus", name: "Add tail", action: { viewStore.send(.addNew(-2))})
                IconButton(icon: "trash", name: "Delete", disabled: viewStore.tableState.selectIndex < 0, action: {viewStore.send(.deleteConfirm(viewStore.tableState.selectIndex))})
                
                Spacer()
                PageBar(store: store.scope(state: \.pageState, action: ListValueStore.Action.pageAction))
            }
            .padding(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
            
            
            NTableView(store: store.scope(state: \.tableState, action: ListValueStore.Action.tableAction))

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
            ModalView("Edit list item", action: {viewStore.send(.submit)}) {
                VStack(alignment:.leading, spacing: MTheme.V_SPACING) {
                    FormItemTextArea(label: "", placeholder: "value", value: viewStore.$editValue)
                }
                
            }
        }
        }
    }
}

//struct ListEditorView_Previews: PreviewProvider {
//    static var redisKeyModel:RedisKeyModel = RedisKeyModel(key: "tes", type: "string")
//    static var previews: some View {
//        ListEditorView(redisKeyModel: redisKeyModel)
//    }
//}
