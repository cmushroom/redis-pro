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
        WithViewStore(store) {viewStore in
            VStack(alignment: .leading, spacing: 4)  {
                if viewStore.keyState.type == RedisKeyTypeEnum.STRING.rawValue {
                    StringEditorView(store: store.scope(state: \.stringValueState, action: ValueAction.stringValueAction))
                }
                else if viewStore.keyState.type == RedisKeyTypeEnum.HASH.rawValue {
                    HashEditorView(store: store.scope(state: \.hashValueState, action: ValueAction.hashValueAction))
                }
//                else if RedisKeyTypeEnum.LIST.rawValue == redisKeyModel.type {
                //                ListEditorView(onSubmit: onSubmit)
                //            } else if RedisKeyTypeEnum.SET.rawValue == redisKeyModel.type {
                //                SetEditorView(onSubmit: onSubmit)
                //            } else if RedisKeyTypeEnum.ZSET.rawValue == redisKeyModel.type {
                //                ZSetEditorView(onSubmit: onSubmit)
                //            } else {
                //                EmptyView()
                //            }
            }
        }
        
    }
    
}

//struct RedisValueEditView_Previews: PreviewProvider {
//    static var previews: some View {
//        RedisValueEditView(redisKeyModel: RedisKeyModel(key: "user_session:1234", type: RedisKeyTypeEnum.STRING.rawValue))
//    }
//}
