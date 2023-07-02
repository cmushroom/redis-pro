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
    
    var store: StoreOf<KeyStore>
    let logger = Logger(label: "redis-value-header")
    
    private func ttlView(_ viewStore: ViewStore<KeyStore.State, KeyStore.Action>) -> some View {
        HStack(alignment:.center, spacing: 0) {
            FormItemInt(label: "TTL(s)", value: viewStore.binding(get: \.ttl, send: KeyStore.Action.setTtl), suffix: "square.and.pencil", onCommit: { viewStore.send(.saveTtl)})
                .disabled(viewStore.isNew)
                .help("HELP_TTL")
                .frame(width: 260)
        }
    }
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) {viewStore in
            
            HStack(alignment: .center, spacing: 6) {
                FormItemText(label: "Key", labelWidth: 40, required: true, editable: viewStore.isNew, value: viewStore.binding(get: \.key, send: KeyStore.Action.setKey))
                    .frame(maxWidth: .infinity)

                Spacer()
                RedisKeyTypePicker(label: "Type", value: viewStore.binding(get: \.type, send: KeyStore.Action.setType), disabled: !viewStore.isNew)
                ttlView(viewStore)
            }
        }
    }
    
}

//struct RedisValueHeaderView_Previews: PreviewProvider {
//    static var previews: some View {
//        RedisValueHeaderView(redisKeyModel: RedisKeyModel(key: "test", type: RedisKeyTypeEnum.STRING.rawValue))
//    }
//}
