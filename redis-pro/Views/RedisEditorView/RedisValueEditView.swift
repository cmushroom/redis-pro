//
//  RedisValueEditView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/7.
//

import SwiftUI
import Logging
import ComposableArchitecture

struct RedisValueEditView: View {
    
    var store: Store<ValueState, ValueAction>
    
    let logger = Logger(label: "redis-value-edit-view")
    
    var body: some View {
        WithViewStore(store.scope(state: \.keyState)) {viewStore in
            VStack(alignment: .leading, spacing: 4)  {
                if viewStore.type == RedisKeyTypeEnum.STRING.rawValue {
                    StringEditorView(store: store.scope(state: \.stringValueState, action: ValueAction.stringValueAction))
                }
                // HASH
                else if viewStore.type == RedisKeyTypeEnum.HASH.rawValue {
                    HashEditorView(store: store.scope(state: \.hashValueState, action: ValueAction.hashValueAction))
                }
                // LIST
                else if viewStore.type == RedisKeyTypeEnum.LIST.rawValue {
                    ListEditorView(store: store.scope(state: \.listValueState, action: ValueAction.listValueAction))
                }
                // SET
                else if viewStore.type == RedisKeyTypeEnum.SET.rawValue {
                    SetEditorView(store: store.scope(state: \.setValueState, action: ValueAction.setValueAction))
                }
                // ZSET
                else if viewStore.type == RedisKeyTypeEnum.ZSET.rawValue {
                    ZSetEditorView(store: store.scope(state: \.zsetValueState, action: ValueAction.zsetValueAction))
                } else {
                    EmptyView()
                }
            }
        }
        
    }
    
}

//struct RedisValueEditView_Previews: PreviewProvider {
//    static var previews: some View {
//        RedisValueEditView(redisKeyModel: RedisKeyModel(key: "user_session:1234", type: RedisKeyTypeEnum.STRING.rawValue))
//    }
//}
