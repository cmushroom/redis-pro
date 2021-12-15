//
//  RedisKeysTableDemo.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/7/9.
//

import SwiftUI

struct RedisKeysTableDemo: View {
    @State var datasource = [NSRedisKeyModel]()
    @State var selectRowIndex:Int?
    
    var body: some View {
        RedisKeysTable(datasource: $datasource, selectRowIndex: $selectRowIndex)
            .onAppear {
                self.getData()
            }
    }
    
    func getData() -> Void {
//        datasource.append(RedisKeyTableRow(no: 1, type: RedisKeyTypeEnum.STRING.rawValue, key: "user_token-1"))
//        datasource.append(RedisKeyTableRow(no: 2, type: RedisKeyTypeEnum.LIST.rawValue, key: "user_token-2"))
//        datasource.append(RedisKeyTableRow(no: 2, type: RedisKeyTypeEnum.SET.rawValue, key: "user_token-2"))
//        datasource.append(RedisKeyTableRow(no: 2, type: RedisKeyTypeEnum.ZSET.rawValue, key: "user_token-2"))
//        datasource.append(RedisKeyTableRow(no: 100, type: RedisKeyTypeEnum.HASH.rawValue, key: "user_session-1"))
        
        datasource.append(NSRedisKeyModel("aaaa", type: RedisKeyTypeEnum.STRING.rawValue))
    }
}

struct RedisKeysTableDemo_Previews: PreviewProvider {
    static var previews: some View {
        RedisKeysTableDemo()
    }
}
