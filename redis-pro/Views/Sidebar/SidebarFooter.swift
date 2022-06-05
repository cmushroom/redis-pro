//
//  SidebarFooter.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/5/8.
//

import SwiftUI
import Logging

struct SidebarFooter: View {
    @EnvironmentObject var globalContext:GlobalContext
    @EnvironmentObject var redisInstanceModel:RedisInstanceModel
    @ObservedObject var page:Page
    var pageAction:() throws -> Void = {}
    
    let logger = Logger(label: "sidebar-footer")
    
    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            MenuButton(label:
                        Label("", systemImage: "ellipsis.circle")
                        .labelStyle(IconOnlyLabelStyle())
            ){
                Button("Redis Info", action: onRedisInfoAction)
            }
            .frame(width:30)
            .menuButtonStyle(BorderlessPullDownMenuButtonStyle())
            
            MIcon(icon: "arrow.clockwise", fontSize: 12, action: onRefreshAction)
                .help("HELP_REFRESH")
            
            PageBar(page: page, action: pageAction)
        }
        .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 6))
    }
    
    func onRefreshAction() -> Void {
        do {
            page.firstPage()
            try pageAction()
        } catch {
            globalContext.showError(error)
        }
    }
    
    func onRedisInfoAction() -> Void {
        Task {
            let _ = await redisInstanceModel.getClient().info()
        }
    }
    
}

struct SidebarFooter_Previews: PreviewProvider {
    @StateObject static  var page:Page = Page()
    static var previews: some View {
        SidebarFooter(page: page)
    }
}
