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
    
    @Perception.Bindable var store:StoreOf<ListValueStore>
    var keyObjectStore: StoreOf<KeyObjectStore>
    let logger = Logger(label: "redis-list-editor")
    
    init(store: StoreOf<ValueStore>) {
        self.store = store.scope(state: \.listValueState, action: \.listValueAction)
        self.keyObjectStore = store.scope(state: \.keyObjectState, action: \.keyObjectAction)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center , spacing: 4) {
                IconButton(icon: "plus", name: "Add head", action: { store.send(.addNew(-1))})
                IconButton(icon: "plus", name: "Add tail", action: { store.send(.addNew(-2))})
                IconButton(icon: "trash", name: "Delete", disabled: store.tableState.selectIndex < 0, action: {store.send(.deleteConfirm(store.tableState.selectIndex))})
                
                Spacer()
                PageBar(store: store.scope(state: \.pageState, action: \.pageAction))
            }
            .padding(EdgeInsets(top: MTheme.V_SPACING, leading: 0, bottom: MTheme.V_SPACING, trailing: 0))
            
            
            NTableView(store: store.scope(state: \.tableState, action: \.tableAction))

            // footer
            HStack(alignment: .center, spacing: MTheme.H_SPACING) {
                KeyObjectBar(store: keyObjectStore)
                Spacer()
                IconButton(icon: "arrow.clockwise", name: "Refresh", action: {store.send(.refresh)})
            }
            .padding(EdgeInsets(top: MTheme.V_SPACING, leading: 0, bottom: 0, trailing: 0))
        }
        .sheet(isPresented: $store.editModalVisible, onDismiss: {
        }) {
            WithPerceptionTracking {
                ModalView("Edit list item", action: {store.send(.submit)}) {
                    VStack(alignment:.leading, spacing: MTheme.V_SPACING) {
                        FormItemTextArea(label: "", placeholder: "value", value: $store.editValue)
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
