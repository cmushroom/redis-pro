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
    var store: Store<HashValueState, HashValueAction>
    private let logger = Logger(label: "redis-hash-editor")
    
    var body: some View {
        WithViewStore(store) {viewStore in
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center , spacing: MTheme.H_SPACING) {
                    IconButton(icon: "plus", name: "Add", action: {viewStore.send(.addNew)})
                    IconButton(icon: "trash", name: "Delete", disabled: viewStore.tableState.selectIndex < 0, action: {viewStore.send(.deleteConfirm(viewStore.tableState.selectIndex))})
                
                    SearchBar(placeholder: "Search field...", onCommit: {viewStore.send(.search($0))})
                    PageBar(showTotal: true, store: store.scope(state: \.pageState, action: HashValueAction.pageAction))
                }
                .padding(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                
                NTableView(store: store.scope(state: \.tableState, action: HashValueAction.tableAction))

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
                        FormItemText(placeholder: "Field", value: viewStore.binding(\.$field)).disabled(!viewStore.isNew)
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
