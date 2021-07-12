//
//  ClientsListView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/6/18.
//

import SwiftUI

struct ClientsListView: View {
    @EnvironmentObject var redisInstanceModel:RedisInstanceModel
    @State private var clientModels:[ClientModel] = [ClientModel]()
    @State var selectRowIndex: Int?
    
    var selectClientAddr:String {
        selectRowIndex == nil ? "" : self.clientModels[self.selectRowIndex!].addr
    }
    
    private var footer: some View {
        HStack(alignment: .center , spacing: 8) {
            Spacer()
            MButton(text: "Kill Client", action: clientKill, disabled: selectRowIndex == nil, isConfirm: true, confirmTitle: selectRowIndex == nil ? "" : "Kill Client?",
                confirmMessage: "Are you sure you want to kill client:\(selectClientAddr)? This operation cannot be undone.")
            MButton(text: "Refresh", action: onRefrehAction)
        }
    }
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            ClientListTable(datasource: $clientModels, selectRowIndex: $selectRowIndex)
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
            self.clientModels = res
        })
    }
    func clientKill() -> Void {
        if self.selectRowIndex == nil {
            return
        }
        
        let _ = redisInstanceModel.getClient().clientKill(self.clientModels[self.selectRowIndex!]).done({_ in
            self.onRefrehAction()
        })
    }
}

struct ClientsListView_Previews: PreviewProvider {
    static var previews: some View {
        ClientsListView()
    }
}
