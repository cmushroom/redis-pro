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
    @State private var selection:String?
    
    private var columns:[String] = ["id", "name", "addr", "laddr", "fd", "age", "idle", "flags", "db", "sub", "psub", "multi", "qbuf", "qbuf-free", "obl", "oll", "omem", "events", "cmd", "argv-mem", "tot-mem", "redir", "user"]
    
    private func clientRow(_ clientModel:[String:String], width: CGFloat) -> some View {
        let width = width / CGFloat(columns.count)
        
        return VStack(spacing: 0){
            HStack(alignment: .center, spacing: 8) {
                ForEach(columns, id:\.self) { column in
                    Text(clientModel[column] ?? "-")
                        .frame(width: 60, alignment: .center)
                }
            }
            .padding(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
            
            Rectangle().frame(height: 1)
                .padding(.horizontal, 0).foregroundColor(Color.gray.opacity(0.1))
        }
        .listRowInsets(EdgeInsets())
    }
    private var footer: some View {
        HStack(alignment: .center , spacing: 8) {
            Spacer()
            MButton(text: "Refresh", action: onRefrehAction)
        }
    }
    
    
    var body: some View {
        
        GeometryReader { geometry in
            let width = geometry.size.width / CGFloat(columns.count)
            
            VStack(alignment: .leading, spacing: 10) {
                
                List(selection: $selection) {
                    ScrollView(.horizontal, showsIndicators: true) {
                        Section(header: HStack {
                            ForEach(columns, id:\.self) { column in
                                Text(column).help(LocalizedStringKey("REDIS_CLIENT_LIST_\(column)".uppercased()))
                                    .frame(width: 60, alignment: .center)
                            }
                        }) {
                            
                            ForEach(0 ..< clientModels.count, id:\.self) { index in
                                clientRow(clientModels[index], width: geometry.size.width)
                            }
                            
                        }
                        .collapsible(false)
                    }
                }
                .listStyle(PlainListStyle())
                .frame(minWidth: 500, minHeight: 400)
                
                footer
            }
            Spacer()
        }
        .padding(EdgeInsets(top: 10, leading: 8, bottom: 10, trailing: 8))
        .onAppear {
            getClients()
        }
    }
    
    func getClients() -> Void {
        let _ = redisInstanceModel.getClient().clientList().done({res in
            self.clientModels = res
            print("sfsfsafsdf \(res)")
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
