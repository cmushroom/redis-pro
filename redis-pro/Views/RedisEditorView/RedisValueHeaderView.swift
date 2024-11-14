//
//  RedisValueHeaderView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/7.
//

import SwiftUI
import Logging
import ComposableArchitecture

struct RedisValueHeaderView: View {
    
    @Perception.Bindable var store: StoreOf<KeyStore>
    let logger = Logger(label: "redis-value-header")
    
    private func ttlView() -> some View {
        HStack(alignment:.center, spacing: 0) {
            FormItemInt(label: "TTL(s)", value: $store.ttl, suffix: "square.and.pencil", onCommit: { store.send(.saveTtl)})
                .disabled(store.isNew)
                .help("HELP_TTL")
                .frame(width: 260)
        }
    }
    
    var body: some View {
            
        HStack(alignment: .center, spacing: 6) {
            FormItemText(label: "Key", labelWidth: 40, required: true, editable: store.isNew, value: $store.key)
                .frame(maxWidth: .infinity)

            Spacer()
            RedisKeyTypePicker(label: "Type", value: $store.type, disabled: !store.isNew)
            ttlView()
        }
        
    }
    
}
