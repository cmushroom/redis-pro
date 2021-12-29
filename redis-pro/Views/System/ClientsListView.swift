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
    @State private var selectRowIndex: Int = -1
    
    var selectClientAddr:String {
        selectRowIndex == -1 ? "" : self.clientModels[self.selectRowIndex].addr
    }
    
    private var footer: some View {
        HStack(alignment: .center , spacing: 8) {
            Spacer()
            MButton(text: "Kill Client", action: clientKill, disabled: selectRowIndex == -1, isConfirm: true, confirmTitle: selectRowIndex == -1 ? "" : "Kill Client?",
                confirmMessage: "Are you sure you want to kill client:\(selectClientAddr)? This operation cannot be undone.")
            MButton(text: "Refresh", action: onRefrehAction)
        }
    }
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: MTheme.V_SPACING) {
            
            ClientListTable(datasource: $clientModels, selectRowIndex: $selectRowIndex)
            footer
        }
//        .padding(EdgeInsets(top: 10, leading: 8, bottom: 10, trailing: 8))
        .onAppear {
            onRefrehAction()
        }
    }
    
    func getClients() async -> Void {
        let res = await redisInstanceModel.getClient().clientList()
        self.clientModels = res
    }
    func onRefrehAction() -> Void {
        Task {
            await getClients()
        }
    }
    func clientKill() -> Void {
        if self.selectRowIndex == -1 {
            return
        }
        
        let client = self.clientModels[self.selectRowIndex]
        
        Task {
            let r = await redisInstanceModel.getClient().clientKill(client)
            if r {
                await self.getClients()
            }
        }
    }
}

struct ClientsListView_Previews: PreviewProvider {
    static var previews: some View {
        ClientsListView()
    }
}
