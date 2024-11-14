//
//  KeyValueRowEditorView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/9.
//

import SwiftUI
import Logging
import ComposableArchitecture

struct HashEditorView: View {
    @Perception.Bindable var store: StoreOf<HashValueStore>
    var keyObjectStore: StoreOf<KeyObjectStore>
    private let logger = Logger(label: "redis-hash-editor")
    
    init(store: StoreOf<ValueStore>) {
        self.store = store.scope(state: \.hashValueState, action: \.hashValueAction)
        self.keyObjectStore = store.scope(state: \.keyObjectState, action: \.keyObjectAction)
    }
    
    
    var body: some View {
    
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center , spacing: MTheme.H_SPACING) {
                IconButton(icon: "plus", name: "Add", action: {store.send(.addNew)})
                IconButton(icon: "trash", name: "Delete", disabled: store.tableState.selectIndex < 0, action: {store.send(.deleteConfirm(store.tableState.selectIndex))})
            
                SearchBar(placeholder: "Search field...", onCommit: {store.send(.search($0))})
                PageBar(store: store.scope(state: \.pageState, action: \.pageAction))
            }
            .padding(EdgeInsets(top: MTheme.V_SPACING, leading: 0, bottom: MTheme.V_SPACING, trailing: 0))
            
            NTableView(store: store.scope(state: \.tableState, action: \.tableAction))

            // footer
            HStack(alignment: .center, spacing: 0) {
                KeyObjectBar(store: keyObjectStore)
                Spacer()
                IconButton(icon: "arrow.clockwise", name: "Refresh", action: {store.send(.refresh)})

            }
            .padding(EdgeInsets(top: MTheme.V_SPACING, leading: 0, bottom: 0, trailing: 0))
        }
        .onAppear {
            logger.info("redis hash editor view appear ...")
            store.send(.initial)
        }
        .sheet(isPresented: $store.editModalVisible, onDismiss: {
        }) {
            WithPerceptionTracking {
                ModalView("Edit hash entry", action: {store.send(.submit)}) {
                    VStack(alignment:.leading, spacing: 8) {
                        FormItemText(placeholder: "Field", editable: store.isNew, value: $store.field)
                        FormItemTextArea(placeholder: "Value", value: $store.value)
                    }
                }
            }
        }
        
    }
    
}
