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
    
    var store: Store<KeyState, KeyAction>
    let logger = Logger(label: "redis-value-header")
    
    private func ttlView(_ viewStore: ViewStore<KeyState, KeyAction>) -> some View {
        HStack(alignment:.center, spacing: 0) {
            FormItemInt(label: "TTL(s)", value: viewStore.binding(get: \.ttl, send: KeyAction.setTtl), suffix: "square.and.pencil", onCommit: { viewStore.send(.saveTtl)})
                .disabled(viewStore.isNew)
                .help("HELP_TTL")
                .frame(width: 260)
        }
    }
    
    var body: some View {
        WithViewStore(store) {viewStore in
            
            HStack(alignment: .center, spacing: 6) {
                FormItemText(label: "Key", labelWidth: 40, required: true, value: viewStore.binding(\.$key)).disabled(!viewStore.isNew)
                RedisKeyTypePicker(label: "Type", value: viewStore.binding(get: \.type, send: KeyAction.setType), disabled: !viewStore.isNew)
                Spacer()
                
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
