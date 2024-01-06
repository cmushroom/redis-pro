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
    var store: StoreOf<HashValueStore>
    var keyObjectStore: StoreOf<KeyObjectStore>
    private let logger = Logger(label: "redis-hash-editor")
    
    init(store: StoreOf<ValueStore>) {
        self.store = store.scope(state: \.hashValueState, action: ValueStore.Action.hashValueAction)
        self.keyObjectStore = store.scope(state: \.keyObjectState, action: ValueStore.Action.keyObjectAction)
    }
    
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) {viewStore in
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center , spacing: MTheme.H_SPACING) {
                    IconButton(icon: "plus", name: "Add", action: {viewStore.send(.addNew)})
                    IconButton(icon: "trash", name: "Delete", disabled: viewStore.tableState.selectIndex < 0, action: {viewStore.send(.deleteConfirm(viewStore.tableState.selectIndex))})
                
                    SearchBar(placeholder: "Search field...", onCommit: {viewStore.send(.search($0))})
                    PageBar(store: store.scope(state: \.pageState, action: HashValueStore.Action.pageAction))
                }
                .padding(EdgeInsets(top: MTheme.V_SPACING, leading: 0, bottom: MTheme.V_SPACING, trailing: 0))
                
                NTableView(store: store.scope(state: \.tableState, action: HashValueStore.Action.tableAction))

                // footer
                HStack(alignment: .center, spacing: 0) {
                    KeyObjectBar(store: keyObjectStore)
                    Spacer()
                    IconButton(icon: "arrow.clockwise", name: "Refresh", action: {viewStore.send(.refresh)})

                }
                .padding(EdgeInsets(top: MTheme.V_SPACING, leading: 0, bottom: 0, trailing: 0))
            }
            .onAppear {
                logger.info("redis hash editor view appear ...")
                viewStore.send(.initial)
            }
            .sheet(isPresented: viewStore.$editModalVisible, onDismiss: {
            }) {
                ModalView("Edit hash entry", action: {viewStore.send(.submit)}) {
                    VStack(alignment:.leading, spacing: 8) {
                        FormItemText(placeholder: "Field", editable: viewStore.isNew, value: viewStore.$field)
                        FormItemTextArea(placeholder: "Value", value: viewStore.$value)
                    }
                }
            }
        }
    }
    
}
