//
//  RedisListTableDemo.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/7/12.
//

import SwiftUI

struct RedisListTableDemo: View {
    @State var datasource:[RedisModel] = [RedisModel(), RedisModel()]
    @State var selectIndex:Int?
    
    var body: some View {
        RedisListTable(datasource: $datasource, selectRowIndex: $selectIndex)
    }
}

struct RedisListTableDemo_Previews: PreviewProvider {
    static var previews: some View {
        RedisListTableDemo()
    }
}
