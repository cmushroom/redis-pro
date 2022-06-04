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
    
    var store:Store<SetValueState, SetValueAction>
    let logger = Logger(label: "redis-set-editor")
    
    var body: some View {
        WithViewStore(store) { viewStore in
            
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center , spacing: 4) {
                IconButton(icon: "plus", name: "Add", action: {viewStore.send(.addNew)})
                IconButton(icon: "trash", name: "Delete", disabled: viewStore.tableState.selectIndex < 0, action: {viewStore.send(.deleteConfirm(viewStore.tableState.selectIndex))})

                SearchBar(placeholder: "Search element...", onCommit: {viewStore.send(.search($0))})
                PageBar(showTotal: true, store: store.scope(state: \.pageState, action: SetValueAction.pageAction))
            }
            .padding(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
            
            NTableView(store: store.scope(state: \.tableState, action: SetValueAction.tableAction))

            
            // footer
            HStack(alignment: .center, spacing: MTheme.H_SPACING) {
                Spacer()
                IconButton(icon: "arrow.clockwise", name: "Refresh", action: {viewStore.send(.refresh)})
            }
            .padding(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
        }
        .sheet(isPresented: viewStore.binding(\.$editModalVisible), onDismiss: {
        }) {
            ModalView("Edit set element", action: {viewStore.send(.submit)}) {
                VStack(alignment:.leading, spacing: MTheme.V_SPACING) {
                    FormItemTextArea(label: "Value", placeholder: "value", value: viewStore.binding(\.$editValue))
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
