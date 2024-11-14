//
//  RedisKeysList.swift
//  redis-pro
//
//  Created by chengpan on 2021/4/4.
//

import SwiftUI
import Logging
import ComposableArchitecture

struct RedisKeysListView: View {
    
    var appStore:StoreOf<AppStore>
    var store:StoreOf<RedisKeysStore>
    let logger = Logger(label: "redis-key-list-view")
    
    init(_ store:StoreOf<AppStore>) {
        self.appStore = store
        self.store = store.scope(state: \.redisKeysState, action: \.redisKeysAction)
    }
    
    private func sidebarHeader(_ store: StoreOf<RedisKeysStore>) -> some View {
        VStack(alignment: .center, spacing: 0) {
            VStack(alignment: .center, spacing: 4) {
                // redis search ...
                SearchBar(placeholder: "Search keys...", onCommit: {store.send(.search($0))})
                    .padding(EdgeInsets(top: 4, leading: 0, bottom: 2, trailing: 0))
                
                // redis key operate ...
                HStack {
                    IconButton(icon: "plus", name: "Add", action: {store.send(.addNew)})
                    IconButton(icon: "trash", name: "Delete", disabled: !store.tableState.isSelect
                               ,action: { store.send(.deleteConfirm(store.tableState.selectIndexes))})
                    
                    Spacer()
                    DatabasePicker(store: store.scope(state: \.databaseState, action: \.databaseAction))
                }
            }
            .padding(EdgeInsets(top: 4, leading: 4, bottom: 8, trailing: 4))
//            Rectangle().frame(height: 1)
//                .padding(0)
//                .foregroundColor(Color.gray.opacity(0.6))
//                .zIndex(0)
        }
        .zIndex(1)
    }
    
    private func sidebarFoot(_ store: StoreOf<RedisKeysStore>) -> some View {
        HStack(alignment: .center, spacing: 4) {
            Menu(content: {
                Button("Keys Del", action: { store.send(.redisSystemAction(.setSystemView(.KEYS_DEL))) })
                Button("Redis Info", action: { store.send(.redisSystemAction(.setSystemView(.REDIS_INFO))) })
                Button("Redis Config", action: { store.send(.redisSystemAction(.setSystemView(.REDIS_CONFIG))) })
                Button("Clients List", action: { store.send(.redisSystemAction(.setSystemView(.CLIENT_LIST))) })
                Button("Slow Log", action: { store.send(.redisSystemAction(.setSystemView(.SLOW_LOG))) })
                Button("Lua", action: { store.send(.redisSystemAction(.setSystemView(.LUA))) })
                Button("Flush DB", action: {store.send(.flushDBConfirm)})
            }, label: {
                Label("", systemImage: "ellipsis.circle")
                .foregroundColor(.primary)
                // @since 11.0
                .labelStyle(IconOnlyLabelStyle())
            })
            .frame(width:30)
            .menuStyle(BorderlessButtonMenuStyle())
            
            MIcon(icon: "arrow.clockwise", fontSize: 12, action: {store.send(.refresh)})
                .help("HELP_REFRESH")
            
            Spacer(minLength: 0)
            Text("dbsize: \(store.dbsize)")
                .font(MTheme.FONT_FOOTER)
                .lineLimit(1)
            PageBar(store: store.scope(state: \.pageState, action: \.pageAction))
        }
    }
    
    private func sidebar(_ store: StoreOf<RedisKeysStore>) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // header area
            sidebarHeader(store)
            
            NTableView(store: store.scope(state: \.tableState, action: \.tableAction))
            
            // footer
            sidebarFoot(store)
                .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 6))
            
        }
    }
    
    var body: some View {
        HSplitView {
            // sidebar
            sidebar(store)
                .padding(0)
                .frame(minWidth:280, idealWidth: 360, maxWidth: .infinity)
                .layoutPriority(0)
            
            // content
            VStack(alignment: .leading, spacing: 0){
                if store.mainViewType == MainViewTypeEnum.EDITOR {
                    RedisValueView(store: store.scope(state: \.valueState, action: \.valueAction))
                } else if store.mainViewType == MainViewTypeEnum.SYSTEM {
                    RedisSystemView(store: store.scope(state: \.redisSystemState, action: \.redisSystemAction))
                } else {
                    EmptyView()
                }
                
                Spacer()
            }
            .padding(4)
            .frame(minWidth: 600, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
            .layoutPriority(1)
        }
        .onAppear{
        }
        //FIXME
//        .sheet(isPresented: store.binding(get: \.renameState.visible, send: .renameAction(.hide))) {
//            ModalView("Rename", width: MTheme.DIALOG_W, height: 100, action: {store.send(.renameAction(.submit))}) {
//                VStack(alignment:.leading, spacing: 8) {
//                    //FIXME
////                    FormItemText(label: "New name", placeholder: "New key name", value: $store.renameState.newKey)
//                }
//            }
//        }
        
    }
}
