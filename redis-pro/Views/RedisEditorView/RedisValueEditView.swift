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
    
    var store: StoreOf<ValueStore>
    
    let logger = Logger(label: "redis-value-edit-view")
    
    var body: some View {
        WithViewStore(self.store, observe: { $0.keyState }) { viewStore in
            VStack(alignment: .leading, spacing: 0)  {
                if viewStore.type == RedisKeyTypeEnum.STRING.rawValue {
                    StringEditorView(store: store)
                }
                // HASH
                else if viewStore.type == RedisKeyTypeEnum.HASH.rawValue {
                    HashEditorView(store: store)
                }
                // LIST
                else if viewStore.type == RedisKeyTypeEnum.LIST.rawValue {
                    ListEditorView(store: store)
                }
                // SET
                else if viewStore.type == RedisKeyTypeEnum.SET.rawValue {
                    SetEditorView(store: store)
                }
                // ZSET
                else if viewStore.type == RedisKeyTypeEnum.ZSET.rawValue {
                    ZSetEditorView(store: store)
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
