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
    private let logger = Logger(label: "redis-hash-editor")
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) {viewStore in
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center , spacing: MTheme.H_SPACING) {
                    IconButton(icon: "plus", name: "Add", action: {viewStore.send(.addNew)})
                    IconButton(icon: "trash", name: "Delete", disabled: viewStore.tableState.selectIndex < 0, action: {viewStore.send(.deleteConfirm(viewStore.tableState.selectIndex))})
                
                    SearchBar(placeholder: "Search field...", onCommit: {viewStore.send(.search($0))})
                    PageBar(store: store.scope(state: \.pageState, action: HashValueStore.Action.pageAction))
                }
                .padding(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                
                NTableView(store: store.scope(state: \.tableState, action: HashValueStore.Action.tableAction))

                // footer
                HStack(alignment: .center, spacing: 4) {
                    Spacer()
                    IconButton(icon: "arrow.clockwise", name: "Refresh", action: {viewStore.send(.refresh)})

                }
                .padding(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
            }
            .onAppear {
                logger.info("redis hash editor view appear ...")
                viewStore.send(.initial)
            }
            .sheet(isPresented: viewStore.binding(\.$editModalVisible), onDismiss: {
            }) {
                ModalView("Edit hash entry", action: {viewStore.send(.submit)}) {
                    VStack(alignment:.leading, spacing: 8) {
                        FormItemText(placeholder: "Field", editable: viewStore.isNew, value: viewStore.binding(\.$field))
                        FormItemTextArea(placeholder: "Value", value: viewStore.binding(\.$value))
                    }
                }
            }
        }
    }
    
}

//struct KeyValueRowEditorView_Previews: PreviewProvider {
//    static var redisKeyModel:RedisKeyModel = RedisKeyModel("tes", type: "string")
//    static var previews: some View {
//        HashEditorView(redisKeyModel: redisKeyModel)
//    }
//}
