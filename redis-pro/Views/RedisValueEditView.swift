//
//  RedisValueEditView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/7.
//

import SwiftUI

struct RedisValueEditView: View {
    var redisKeyModel:RedisKeyModel
    var value:Any = "sdf242314324132"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4)  {
            if RedisKeyTypeEnum.STRING.rawValue == redisKeyModel.type {
                StringEditorView(text: value as! String)
            } else if RedisKeyTypeEnum.HASH.rawValue == redisKeyModel.type {
                KeyValueRowEditorView(text: value as! String)
            }
        }
        .padding(4)
    }
}

struct RedisValueEditView_Previews: PreviewProvider {
    static var previews: some View {
        RedisValueEditView(redisKeyModel: RedisKeyModel(id: "user_session:1234", type: RedisKeyTypeEnum.STRING.rawValue), value: "123456")
    }
}
