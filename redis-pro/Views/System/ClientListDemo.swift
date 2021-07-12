//
//  ClientListDemo.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/6/25.
//

import SwiftUI
import Cocoa

struct ClientListDemo: View {
    var body: some View {
        Text("REDIS_CLIENT_LIST_ID")
    }
}

struct ClientListDemo_Previews: PreviewProvider {
    
    @State static var list = [ClientModel(), ClientModel()]
    @State static var selectRowIndex: Int?
    
    static var previews: some View {
        VStack {
            Text("REDIS_CLIENT_LIST_ID")
            ClientListTable(datasource: $list, selectRowIndex: $selectRowIndex)
        }
    }
}



