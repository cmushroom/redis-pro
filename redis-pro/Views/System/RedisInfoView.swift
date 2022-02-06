//
//  RedisInfoView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/6/10.
//

import SwiftUI

struct RedisInfoView: View {
    @EnvironmentObject var redisInstanceModel:RedisInstanceModel
    @State private var redisInfoModels:[RedisInfoModel] = [RedisInfoModel(section: "# Server")]
    @State private var selectIndex:Int?
    
    private var footer: some View {
        HStack(alignment: .center , spacing: MTheme.H_SPACING) {
            Spacer()
            MButton(text: "Reset State", action: onResetStateAction)
            MButton(text: "Refresh", action: onRefrehAction)
        }
    }
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: MTheme.V_SPACING) {
            TabView {
                ForEach(redisInfoModels.indices, id:\.self) { index in
                    
                    RedisInfoTable(datasource: $redisInfoModels[index].infos, selectRowIndex: $selectIndex)
                        .tabItem {
                            Text(redisInfoModels[index].section)
                        }
                        .tag(redisInfoModels[index].section)
                }
            }
            .frame(minWidth: 500, minHeight: 600)
            
            footer
        }
        .onAppear {
            getInfo()
        }
    }
    
    func getInfo() -> Void {
        Task {
            let res = await redisInstanceModel.getClient().info()
            self.redisInfoModels = res
        }
    }
    func onRefrehAction() -> Void {
        Task {
            let res = await redisInstanceModel.getClient().info()
            for redisInfoModel in res {
                if let index = self.redisInfoModels.firstIndex(where: {$0.section == redisInfoModel.section}) {
                    self.redisInfoModels[index].infos = redisInfoModel.infos
                }
            }
            
        }
    }
    
    func onResetStateAction() -> Void {
        Task {
            let _ = await redisInstanceModel.getClient().resetState()
            self.onRefrehAction()
        }
    }
}

struct RedisInfoView_Previews: PreviewProvider {
    
    static var redisInstanceModel:RedisInstanceModel = RedisInstanceModel(redisModel: RedisModel(password: ""))
    
    static var previews: some View {
        RedisInfoView().environmentObject(redisInstanceModel)
    }
    
}
