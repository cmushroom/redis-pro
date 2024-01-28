//
//  StringEditView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/7.
//

import SwiftUI
import Logging
import ComposableArchitecture
import FloatingButton

struct StringEditorView: View {
    var store: StoreOf<StringValueStore>
    var keyObjectStore: StoreOf<KeyObjectStore>
    private let logger = Logger(label: "string-editor")
    
    init(store: StoreOf<ValueStore>) {
        self.store = store.scope(state: \.stringValueState, action: ValueStore.Action.stringValueAction)
        self.keyObjectStore = store.scope(state: \.keyObjectState, action: ValueStore.Action.keyObjectAction)
    }
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) {viewStore in
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: MTheme.V_SPACING){
                    MTextEditor(text: viewStore.$text)
                }
                .background(Color.init(NSColor.textBackgroundColor))
                
                // footer
                HStack(alignment: .center, spacing: MTheme.V_SPACING) {
                    KeyObjectBar(store: keyObjectStore)
                    
                    if (viewStore.isIntactString) {
                        FormText(label: "Length:", value: "\(viewStore.length)")
                    } else {
                        Text("Range: 0~\(viewStore.stringMaxLength + 1) / \(viewStore.length)")
                        MButton(text: "Show Intact", action: {viewStore.send(.getIntactString)})
                    }
                
                    Spacer()
                    Menu("Format", content: {
                        Button("Json Pretty", action: { viewStore.send(.jsonPretty)})
                        Button("Json Minify", action: { viewStore.send(.jsonMinify)})
                    })
                    .frame(width:80)
                    IconButton(icon: "arrow.clockwise", name: "Refresh", action: {viewStore.send(.refresh)})
                    IconButton(icon: "checkmark", name: "Submit", disabled: !viewStore.isIntactString, action: {viewStore.send(.submit)})
                }
                .padding(EdgeInsets(top: MTheme.V_SPACING, leading: 0, bottom: 0, trailing: 0))
                
            }
            
            .onAppear {
                logger.info("redis string value editor view appear ...")
            }
        }
    }
    
}

//struct StringEditView_Previews: PreviewProvider {
//    static var redisKeyModel:RedisKeyModel = RedisKeyModel(key: "tes", type: "string")
//    static var previews: some View {
//        StringEditorView(redisKeyModel: redisKeyModel)
//    }
//}
