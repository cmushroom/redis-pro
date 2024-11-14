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
    
    @Perception.Bindable var  store:StoreOf<SetValueStore>
    var keyObjectStore: StoreOf<KeyObjectStore>
    let logger = Logger(label: "redis-set-editor")
    
    init(store: StoreOf<ValueStore>) {
        self.store = store.scope(state: \.setValueState, action: \.setValueAction)
        self.keyObjectStore = store.scope(state: \.keyObjectState, action: \.keyObjectAction)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center , spacing: 4) {
                IconButton(icon: "plus", name: "Add", action: {store.send(.addNew)})
                IconButton(icon: "trash", name: "Delete", disabled: store.tableState.selectIndex < 0, action: {store.send(.deleteConfirm(store.tableState.selectIndex))})

                SearchBar(placeholder: "Search element...", onCommit: {store.send(.search($0))})
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
                ModalView("Edit set element", action: {store.send(.submit)}) {
                    VStack(alignment:.leading, spacing: MTheme.V_SPACING) {
                        FormItemTextArea(placeholder: "value", value: $store.editValue)
                    }
                }
            }
        }
    }
}
