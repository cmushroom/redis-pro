//
//  RedisKeysList.swift
//  redis-pro
//
//  Created by chengpan on 2021/4/4.
//

import SwiftUI
import Logging
import PromiseKit
import AppKit

struct RedisKeysListView: View {
    @EnvironmentObject var redisInstanceModel:RedisInstanceModel
    @EnvironmentObject var globalContext:GlobalContext
    @State private var redisKeyModels:[NSRedisKeyModel] = [NSRedisKeyModel]()
    @State private var selectedRedisKeyIndex:Int = -1
    @StateObject private var scanModel:Page = Page()
    @StateObject private var page:ScanModel = ScanModel()
    
    @State private var selectRedisKeyModel:RedisKeyModel = RedisKeyModel()
    
    @State private var renameModalVisible:Bool = false
    @State private var oldKeyIndex:Int?
    @State private var newKeyName:String = ""
    
    @State private var dbsize:Int = 0
    
    @State private var mainViewType:MainViewTypeEnum = MainViewTypeEnum.EDITOR
    
    let logger = Logger(label: "redis-key-list-view")
    
//    var selectRedisKeyModel:RedisKeyModel? {
//        get {
//            return (selectedRedisKeyIndex == nil || redisKeyModels.isEmpty || redisKeyModels.count <= selectedRedisKeyIndex!) ? nil : redisKeyModels[selectedRedisKeyIndex!]
//        }
//    }
    
    var selectRedisKey:String {
        selectRedisKeyModel.key
    }
    
    private var sidebarHeader: some View {
        VStack(alignment: .center, spacing: 0) {
            VStack(alignment: .center, spacing: 2) {
                // redis search ...
                SearchBar(keywords: $scanModel.keywords, placeholder: "Search keys...", onCommit: onSearchKeyAction)
                    .padding(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                
                // redis key operate ...
                HStack {
                    IconButton(icon: "plus", name: "Add", action: onAddAction)
                    IconButton(icon: "trash", name: "Delete", disabled: selectedRedisKeyIndex == -1, isConfirm: true,
                               confirmTitle: String(format: Helps.DELETE_KEY_CONFIRM_TITLE, selectRedisKey),
                               confirmMessage: String(format:Helps.DELETE_KEY_CONFIRM_MESSAGE, selectRedisKey),
                               confirmPrimaryButtonText: "Delete",
                               action: onDeleteAction)
                    
                    Spacer()
                    DatabasePicker(database: redisInstanceModel.redisModel.database, action: onRefreshAction)
                }
            }
            .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
            Rectangle().frame(height: 1)
                .padding(.horizontal, 0).foregroundColor(Color.gray.opacity(0.6))
        }
    }
    
    private var sidebarFoot: some View {
        HStack(alignment: .center, spacing: 4) {
            Menu(content: {
                Button("Redis Info", action: onRedisInfoAction)
                Button("Redis Config", action: onRedisConfigAction)
                Button("Clients List", action: onShowClientsAction)
                Button("Slow Log", action: onShowSlowLogAction)
                Button("Flush DB", action: onConfirmFlushDBAction)
            }, label: {
                Label("", systemImage: "ellipsis.circle")
                .foregroundColor(.primary)
                // @since 11.0
                .labelStyle(IconOnlyLabelStyle())
            })
            .frame(width:30)
            .menuStyle(BorderlessButtonMenuStyle())
            
            MIcon(icon: "arrow.clockwise", fontSize: 12, action: onRefreshAction)
                .help(Helps.REFRESH)
            
            Spacer(minLength: 0)
            Text("dbsize: \(dbsize)")
                .font(MTheme.FONT_FOOTER)
                .lineLimit(1)
            PageBar(page: scanModel, action: onQueryKeyPageAction, showTotal: false)
//            ScanBar(scanModel: page, action: onQueryKeyPageAction, showTotal: false)
        }
    }
    
    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            // header area
            sidebarHeader
            
            RedisKeysTable(datasource: $redisKeyModels, selectRowIndex: $selectedRedisKeyIndex, onChange: {
                let select = RedisKeyModel(redisKeyModels[$0])
                self.selectRedisKeyModel = select
                logger.info("set redis model \(self.selectRedisKeyModel)")
                if self.mainViewType != MainViewTypeEnum.EDITOR {
                    self.mainViewType = MainViewTypeEnum.EDITOR
                }
            }, onClick: {_ in
                if self.mainViewType != MainViewTypeEnum.EDITOR {
                    self.mainViewType = MainViewTypeEnum.EDITOR
                }
            }, deleteAction: onDeleteConfirmAction, renameAction: onRenameConfirmAction)
            
            // footer
            sidebarFoot
                .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 6))
            
        }.onTapGesture {
            self.mainViewType = MainViewTypeEnum.EDITOR
        }
    }
    
    private var rightMainView: some View {
        VStack(alignment: .leading, spacing: 0){
            if mainViewType == MainViewTypeEnum.EDITOR {
                if selectedRedisKeyIndex != -1 {
                    RedisValueView(redisKeyModel: $selectRedisKeyModel)
                }
            } else if mainViewType == MainViewTypeEnum.REDIS_INFO {
                RedisInfoView()
            }  else if mainViewType == MainViewTypeEnum.CLIENT_LIST {
                ClientsListView()
            } else if mainViewType == MainViewTypeEnum.SLOW_LOG {
                SlowLogView()
            } else if mainViewType == MainViewTypeEnum.REDIS_CONFIG {
                RedisConfigView()
            } else {
                EmptyView()
            }
            
            Spacer()
        }
        .padding(4)
        .frame(minWidth: 600, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
        .layoutPriority(1)
    }
    
    var body: some View {
        HSplitView {
            // sidebar
            sidebar
                .padding(0)
                .frame(minWidth:280, idealWidth: 360, maxWidth: .infinity)
                .layoutPriority(0)
            
            // content
            rightMainView
        }
        .onAppear{
            onRefreshAction()
        }
        .sheet(isPresented: $renameModalVisible) {
            ModalView("Rename", action: onRenameAction) {
                VStack(alignment:.leading, spacing: 8) {
                    FormItemText(label: "New name", placeholder: "New key name", value: $newKeyName)
                }
                .frame(minWidth:400, minHeight:50)
            }
        }
    }
    
    func onAddAction() -> Void {
//        let newRedisKeyModel = RedisKeyModel(key: "NEW_KEY_\(Date().millis)", type: RedisKeyTypeEnum.STRING.rawValue)
        
        self.selectRedisKeyModel = RedisKeyModel("NEW_KEY_\(Date().millis)", type: RedisKeyTypeEnum.STRING.rawValue)
        
//        self.redisKeyModels.insert(newRedisKeyModel, at: 0)
//        self.selectedRedisKeyIndex = 0
    }
    
    func onRenameConfirmAction(_ index:Int) -> Void {
        self.oldKeyIndex = index
        self.renameModalVisible = true
    }
    
    func onRenameAction() throws -> Void {
        let renameKeyModel = redisKeyModels[oldKeyIndex!]
        let _ = redisInstanceModel.getClient().rename(renameKeyModel.key, newKey: newKeyName).done({r in
            if r {
                renameKeyModel.key = newKeyName
            }
        })
    }
    
    func onDeleteAction() -> Void {
        deleteKey(selectedRedisKeyIndex)
    }
    
    func onDeleteConfirmAction(_ index:Int) -> Void {
        let item = redisKeyModels[index].key
        
        MAlert.confirm(String(format: Helps.DELETE_LIST_ITEM_CONFIRM_TITLE, item)
                       , message: String(format:Helps.DELETE_LIST_ITEM_CONFIRM_MESSAGE, item)
                       , primaryButton: "Delete"
                       , primaryAction: {
                        deleteKey(index)
                       })
    }
    
    func deleteKey(_ index:Int) -> Void {
        if index == -1 {
            return
        }
        
        let redisKeyModel = self.redisKeyModels[index]
        let _ = redisInstanceModel.getClient().del(key: redisKeyModel.key).done({r in
            self.logger.info("on delete redis key: \(index), r:\(r)")
            self.redisKeyModels.remove(at: index)
        })
    }
    
    func onRefreshAction() -> Void {
        self.onSearchKeyAction()
        let _ = self.redisInstanceModel.getClient().dbsizeAsync().done { r in
            self.dbsize = r
        }
    }
    
    func onRedisInfoAction() -> Void {
//        self.selectedRedisKeyIndex = -1
        self.mainViewType = MainViewTypeEnum.REDIS_INFO
    }
    func onRedisConfigAction() -> Void {
//        self.selectedRedisKeyIndex = -1
        self.mainViewType = MainViewTypeEnum.REDIS_CONFIG
    }
    
    func onShowClientsAction() -> Void {
//        self.selectedRedisKeyIndex = -1
        self.mainViewType = MainViewTypeEnum.CLIENT_LIST
    }
    
    func onShowSlowLogAction() -> Void {
//        self.selectedRedisKeyIndex = -1
        self.mainViewType = MainViewTypeEnum.SLOW_LOG
    }
    
    func onConfirmFlushDBAction() -> Void {
        MAlert.confirm("Flush DB ?", message: "Are you sure you want to flush db? This operation cannot be undone.", primaryAction: onFlushDBAction)
    }
    
    func onFlushDBAction() -> Void {
        let _ = self.redisInstanceModel.getClient().flushDB().done({ _ in
            self.onRefreshAction()
        })
    }
    
    func onSearchKeyAction() -> Void {
        scanModel.reset()
        onQueryKeyPageAction()
    }
    
    func onQueryKeyPageAction() -> Void {
        if !redisInstanceModel.isConnect || globalContext.loading {
            return
        }
        
        let promise = self.redisInstanceModel.getClient().pageKeys(scanModel)
        
        let _ = promise.done({ keysPage in
            self.redisKeyModels = keysPage
            
            // 如果有key 默认选中第一个
            if keysPage.count > 0 {
//                self.selectedRedisKeyIndex = 0
//                self.selectRedisKeyModel = self.redisKeyModels
            }
        })
    }
}



func testData() -> [NSRedisKeyModel] {
    let redisKeys:[NSRedisKeyModel] = [NSRedisKeyModel](repeating: NSRedisKeyModel(UUID().uuidString.lowercased(), type: "string"), count: 0)
    return redisKeys
}

//struct RedisKeysList_Previews: PreviewProvider {
//    static var redisInstanceModel:RedisInstanceModel = RedisInstanceModel(redisModel: RedisModel())
//    static var previews: some View {
//        RedisKeysListView(redisKeyModels: testData(), selectedRedisKeyIndex: -1)
//            .environmentObject(redisInstanceModel)
//    }
//}
