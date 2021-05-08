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
    @ObservedObject var redisKeyModel:RedisKeyModel
    
    let logger = Logger(label: "redis-value-edit-view")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4)  {
            if RedisKeyTypeEnum.STRING.rawValue == redisKeyModel.type {
                StringEditorView(redisKeyModel: redisKeyModel)
            } else if RedisKeyTypeEnum.HASH.rawValue == redisKeyModel.type {
                HashEditorView(redisKeyModel: redisKeyModel)
            } else if RedisKeyTypeEnum.LIST.rawValue == redisKeyModel.type {
                ListEditorView(redisKeyModel: redisKeyModel)
            } else if RedisKeyTypeEnum.SET.rawValue == redisKeyModel.type {
                SetEditorView(redisKeyModel: redisKeyModel)
            } else if RedisKeyTypeEnum.ZSET.rawValue == redisKeyModel.type {
                ZSetEditorView(redisKeyModel: redisKeyModel)
            } else {
                EmptyView()
            }
        }
        .padding(4)
        .onChange(of: redisKeyModel, perform: { value in
            logger.info("redis key change \(value)")
            ttl(value)
        })
        .onAppear {
            logger.info("redis value edit view init...")
            ttl(redisKeyModel)
        }
    }
    
    func ttl(_ redisKeyModel:RedisKeyModel) -> Void {
        do {
            let key:String = redisKeyModel.key
            let ttl = try redisInstanceModel.getClient().ttl(key: key)
            redisKeyModel.ttl = ttl
        } catch {
            logger.error("\(error)")
        }
    }
    
}

struct RedisValueEditView_Previews: PreviewProvider {
    static var previews: some View {
        RedisValueEditView(redisKeyModel: RedisKeyModel(key: "user_session:1234", type: RedisKeyTypeEnum.STRING.rawValue))
    }
}
