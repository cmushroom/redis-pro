//
//  ClientsListView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/6/18.
//

import SwiftUI

struct ClientsListView: View {
    @EnvironmentObject var redisInstanceModel:RedisInstanceModel
    @State private var clientModels:[[String:String]] = [[String:String]]()
    @State private var selection:Int?
    
    
//    @State var list = [[String:String]]()
    @State var selectRowIndex: Int = -1
    
    private var columns:[String] = ["id", "name", "addr", "laddr", "fd", "age", "idle", "flags", "db", "sub", "psub", "multi", "qbuf", "qbuf-free", "obl", "oll", "omem", "events", "cmd", "argv-mem", "tot-mem", "redir", "user"]
    
    private var footer: some View {
        HStack(alignment: .center , spacing: 8) {
            Spacer()
            MButton(text: "Kill Client", action: onRefrehAction)
            MButton(text: "Refresh", action: onRefrehAction)
        }
    }
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            ClientListTable(list: $clientModels, selectRowIndex: $selectRowIndex)
            footer
        }
        .padding(EdgeInsets(top: 10, leading: 8, bottom: 10, trailing: 8))
        .onAppear {
            getClients()
        }
    }
    
    func getClients() -> Void {
        let _ = redisInstanceModel.getClient().clientList().done({res in
            self.clientModels = res
        })
    }
    func onRefrehAction() -> Void {
        let _ = redisInstanceModel.getClient().clientList().done({res in
        })
    }
}

struct ClientsListView_Previews: PreviewProvider {
    static var previews: some View {
        ClientsListView()
    }
}
