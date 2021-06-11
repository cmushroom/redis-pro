//
//  RedisInfoView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/6/10.
//

import SwiftUI

struct RedisInfoView: View {
    @EnvironmentObject var redisInstanceModel:RedisInstanceModel
    @State var redisInfoModels:[RedisInfoModel] = [RedisInfoModel(section: "# Server")]
    @State private var selectInfo:String?
    @State private var selectTab:String?
    
    
    private func redisInfoRow(redisInfoModel:RedisInfoModel, infoLine:(String, String), width0:CGFloat,width1:CGFloat,width2:CGFloat) -> some View {
        VStack(spacing: 0){
            HStack(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/, spacing: 8) {
                Text(infoLine.0)
                    .frame(width: width0, alignment: .leading)
                Text(infoLine.1)
                    .frame(width: width1, alignment: .leading)
                Text(LocalizedStringKey("REDIS_INFO_\(redisInfoModel.section)_\(infoLine.0)".uppercased()))
//                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 8))
                    .frame(width: width2, alignment: .leading)
                
            }
            .padding(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
            
            Rectangle().frame(height: 1)
                .padding(.horizontal, 0).foregroundColor(Color.gray.opacity(0.1))
        }
        .listRowInsets(EdgeInsets())
    }
    
    private func tabItem(redisInfoModel:RedisInfoModel, width0:CGFloat,width1:CGFloat,width2:CGFloat) -> some View {
        List(selection: $selectInfo) {
            Section(header: HStack {
                Text("Key")
                    .frame(width: width0, alignment: .leading)
                Text("Value")
                    .frame(width: width1, alignment: .leading)
                Text("Remark")
                    .frame(alignment: .leading)
                    .layoutPriority(1)
            }) {
                ForEach(redisInfoModel.infos, id: \.0) { line in
                    redisInfoRow(redisInfoModel: redisInfoModel, infoLine: line, width0: width0, width1: width1, width2: width2)
                }
            }
            .collapsible(false)
        }
        .listStyle(PlainListStyle())
    }
    
    private var footer: some View {
        HStack(alignment: .center , spacing: 8) {
            Spacer()
            MButton(text: "Refresh", action: onRefrehAction)
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let width0 = geometry.size.width/4
            let width1 = width0
            let width2 = geometry.size.width - width0 - width1 - 40
            
            VStack(alignment: .leading, spacing: 10) {
                TabView {
                    ForEach(redisInfoModels) { item in
                        tabItem(redisInfoModel: item, width0: width0, width1: width1, width2: width2)
                            .tabItem {
                                Text(item.section)
                            }
                            .tag(item.section)
                    }
                }
                .frame(minWidth: 500, minHeight: 600)
                
                footer
            }
            Spacer()
        }
        .padding(EdgeInsets(top: 10, leading: 8, bottom: 10, trailing: 8))
        .onAppear {
            getInfo()
        }
    }
    
    func getInfo() -> Void {
        let _ = redisInstanceModel.getClient().info().done({res in
            self.redisInfoModels = res
        })
    }
    func onRefrehAction() -> Void {
        let _ = redisInstanceModel.getClient().info().done({res in
            for redisInfoModel in res {
                if let index = self.redisInfoModels.firstIndex(where: {$0.section == redisInfoModel.section}) {
                    self.redisInfoModels[index].infos = redisInfoModel.infos
                }
            }
        })
    }
}

struct RedisInfoView_Previews: PreviewProvider {
    
    static var redisInstanceModel:RedisInstanceModel = RedisInstanceModel(redisModel: RedisModel(password: ""))
    
    static var previews: some View {
        RedisInfoView().environmentObject(redisInstanceModel)
    }
    
}
