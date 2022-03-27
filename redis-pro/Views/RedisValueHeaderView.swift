//
//  RedisValueHeaderView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/7.
//

import SwiftUI
import Logging

struct RedisValueHeaderView: View {
    @EnvironmentObject var redisKeyModel:RedisKeyModel
    @EnvironmentObject var redisInstanceModel:RedisInstanceModel
    
    let logger = Logger(label: "redis-value-header")
    
    private var ttlView: some View {
        HStack(alignment:.center, spacing: 0) {
            FormItemInt(label: "TTL(s)", value: $redisKeyModel.ttl, suffix: "square.and.pencil", onCommit: onTTLCommit)
                .help(Helps.TTL_HELP)
                .frame(width: 260)
        }
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 6) {
            FormItemText(label: "Key", labelWidth: 40, required: true, value: $redisKeyModel.key).disabled(!redisKeyModel.isNew)
            RedisKeyTypePicker(label: "Type", value: $redisKeyModel.type, disabled: !redisKeyModel.isNew)
            Spacer()
            
            ttlView
        }
        .onChange(of: redisKeyModel.id, perform: { value in
            logger.info("redis value header key model change \(value)")
            ttl()
        })
        .onAppear {
            logger.info("redis value header view init...")
            ttl()
        }
    }
    
    func onTTLCommit() -> Void {
        if redisKeyModel.isNew {
            return
        }
        logger.info("update redis key ttl: \(redisKeyModel)")
        Task {
            let _ = await redisInstanceModel.getClient().expire(redisKeyModel.key, seconds: redisKeyModel.ttl)
        }
    }
    
    func ttl() -> Void {
        if redisKeyModel.isNew {
            return
        }
        
        Task {
            let r = await redisInstanceModel.getClient().ttl(redisKeyModel.key)
            self.redisKeyModel.ttl = r
        }
    }
    
}

//struct RedisValueHeaderView_Previews: PreviewProvider {
//    static var previews: some View {
//        RedisValueHeaderView(redisKeyModel: RedisKeyModel(key: "test", type: RedisKeyTypeEnum.STRING.rawValue))
//    }
//}
