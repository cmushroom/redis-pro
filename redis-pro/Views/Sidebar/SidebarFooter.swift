//
//  SidebarFooter.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/5/8.
//

import SwiftUI
import Logging

struct RedBorderMenuStyle : MenuStyle {
    func makeBody(configuration: Configuration) -> some View {
        Menu(configuration)
    }
}

struct SidebarFooter: View {
    @EnvironmentObject var globalContext:GlobalContext
    @EnvironmentObject var redisInstanceModel:RedisInstanceModel
    @ObservedObject var page:Page
    @State private var databases:Int = 16
    @State private var selectDB:Int = 0
    var pageAction:() throws -> Void = {}
    
    let logger = Logger(label: "sidebar-footer")
    
    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            MenuButton(label:
                        Label("", systemImage: "ellipsis.circle")
                        .labelStyle(IconOnlyLabelStyle())
            ){
                Button("Order Now", action: onRefreshAction)
                Menu("Database") {
                    ForEach(0 ..< databases) { item in
                        Button("\(item)", action: {onSelectDatabaseAction(item)})
                    }
                }
            }
            .frame(width:30)
            .menuButtonStyle(BorderlessPullDownMenuButtonStyle())
            
            MIcon(icon: "arrow.clockwise", fontSize: 12, action: onRefreshAction)
                .help(Helps.REFRESH)
            //            Picker("DB:", selection: $selectDB) {
            //                ForEach(0 ..< databases) { item in
            //                    Text(String(item)).tag(item)
            //                }
            //            }
            //            .font(/*@START_MENU_TOKEN@*/.footnote/*@END_MENU_TOKEN@*/)
            //            .frame(width:68)
            //            .onChange(of: selectDB, perform: { value in
            //                logger.info("on redis database change: \(value)")
            //            })
            
            PageBar(page: page, action: pageAction)
        }
        .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 6))
        
        .onAppear{
            queryDBList()
        }
    }
    
    func onSelectDatabaseAction(_ database:Int) -> Void {
        print("select database \(database)")
    }
    
    func queryDBList() -> Void {
        do {
            self.databases = try redisInstanceModel.getClient().databases()
        } catch {
            globalContext.showError(error)
        }
    }
    
    func onRefreshAction() -> Void {
        do {
            page.firstPage()
            try pageAction()
        } catch {
            globalContext.showError(error)
        }
    }
    
}

struct SidebarFooter_Previews: PreviewProvider {
    @StateObject static  var page:Page = Page()
    static var previews: some View {
        SidebarFooter(page: page)
    }
}
