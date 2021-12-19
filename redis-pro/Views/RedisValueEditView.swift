//
//  RedisValueEditView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/7.
//

import SwiftUI
import Logging

struct RedisValueEditView: View {
    @EnvironmentObject var redisInstanceModel:RedisInstanceModel
    @EnvironmentObject var redisKeyModel:RedisKeyModel
    var onSubmit: (() -> Void)?
    
    let logger = Logger(label: "redis-value-edit-view")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4)  {
            if RedisKeyTypeEnum.STRING.rawValue == redisKeyModel.type {
                StringEditorView(onSubmit: onSubmit)
            } else if RedisKeyTypeEnum.HASH.rawValue == redisKeyModel.type {
                HashEditorView()
            } else if RedisKeyTypeEnum.LIST.rawValue == redisKeyModel.type {
                ListEditorView()
            } else if RedisKeyTypeEnum.SET.rawValue == redisKeyModel.type {
                SetEditorView()
            } else if RedisKeyTypeEnum.ZSET.rawValue == redisKeyModel.type {
                ZSetEditorView()
            } else {
                EmptyView()
            }
        }

    }
    
}

//struct RedisValueEditView_Previews: PreviewProvider {
//    static var previews: some View {
//        RedisValueEditView(redisKeyModel: RedisKeyModel(key: "user_session:1234", type: RedisKeyTypeEnum.STRING.rawValue))
//    }
//}
