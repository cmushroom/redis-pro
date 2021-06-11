//
//  RedisValueHeaderView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/7.
//

import SwiftUI
import Logging

struct RedisValueHeaderView: View {
    @ObservedObject var redisKeyModel:RedisKeyModel
    @EnvironmentObject var redisInstanceModel:RedisInstanceModel
    
    let logger = Logger(label: "redis-value-header")
    
    private var ttl: some View {
        HStack(alignment:.center, spacing: 0) {
            FormItemInt(label: "TTL(s)", value: $redisKeyModel.ttl, suffix: "square.and.pencil", onCommit: onTTLCommit, autoCommit: false)
                .help(Helps.TTL_HELP)
                .frame(width: 200)
        }
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 6) {
            FormItemText(label: "Key", labelWidth: 40, required: true, value: $redisKeyModel.key, disabled: !redisKeyModel.isNew)
            RedisKeyTypePicker(label: "Type", value: $redisKeyModel.type, disabled: !redisKeyModel.isNew)
            Spacer()
            
            ttl
        }
        .onChange(of: redisKeyModel, perform: { value in
            logger.info("redis value header key model change \(value)")
            ttl(value)
        })
        .onAppear {
            logger.info("redis value header view init...")
            ttl(redisKeyModel)
        }
    }
    
    func onTTLCommit() throws -> Void {
        if redisKeyModel.isNew {
            return
        }
        logger.info("update redis key ttl: \(redisKeyModel)")
        let _ = redisInstanceModel.getClient().expire(redisKeyModel.key, seconds: redisKeyModel.ttl)
    }
    
    func ttl(_ redisKeyModel:RedisKeyModel) -> Void {
        let key:String = redisKeyModel.key
        let _ = redisInstanceModel.getClient().ttl(key: key).done({r in
            redisKeyModel.ttl = r
        })
    }
    
}

struct RedisValueHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        RedisValueHeaderView(redisKeyModel: RedisKeyModel(key: "test", type: RedisKeyTypeEnum.STRING.rawValue))
    }
}
