//
//  StringEditView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/7.
//

import SwiftUI
import Logging
import ComposableArchitecture


struct StringEditorView: View {
    @Perception.Bindable var store: StoreOf<StringValueStore>
    var keyObjectStore: StoreOf<KeyObjectStore>
    private let logger = Logger(label: "string-editor")
    
    init(store: StoreOf<ValueStore>) {
        self.store = store.scope(state: \.stringValueState, action: \.stringValueAction)
        self.keyObjectStore = store.scope(state: \.keyObjectState, action: \.keyObjectAction)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: MTheme.V_SPACING){
                MTextEditor(text: $store.text)
            }
            .background(Color.init(NSColor.textBackgroundColor))
            
            // footer
            HStack(alignment: .center, spacing: MTheme.V_SPACING) {
                KeyObjectBar(store: keyObjectStore)
                
                if (store.isIntactString) {
                    FormText(label: "Length:", value: "\(store.length)")
                } else {
                    Text("Range: 0~\(store.stringMaxLength + 1) / \(store.length)")
                    MButton(text: "Show Intact", action: {store.send(.getIntactString)})
                }
            
                Spacer()
                Menu("Format", content: {
                    Button("Json Pretty", action: { store.send(.jsonPretty)})
                    Button("Json Minify", action: { store.send(.jsonMinify)})
                })
                .frame(width:80)
                IconButton(icon: "arrow.clockwise", name: "Refresh", action: {store.send(.refresh)})
                IconButton(icon: "checkmark", name: "Submit", disabled: !store.isIntactString, action: {store.send(.submit)})
            }
            .padding(EdgeInsets(top: MTheme.V_SPACING, leading: 0, bottom: 0, trailing: 0))
            
        }
        
        .onAppear {
            logger.info("redis string value editor view appear ...")
        }
    }
}
