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
    @State var redisKeyModels:[RedisKeyModel] = [RedisKeyModel]()
    @State var selectedRedisKeyIndex:Int?
//    @StateObject var page:Page = Page()
    @StateObject var scanModel:ScanModel = ScanModel()
    @State private var renameModalVisible:Bool = false
    @State private var oldKeyIndex:Int?
    @State private var newKeyName:String = ""
    @State private var redisInfoVisible:Bool = false
    
    let logger = Logger(label: "redis-key-list-view")
    
    var selectRedisKeyModel:RedisKeyModel? {
        get {
            return (selectedRedisKeyIndex == nil || redisKeyModels.isEmpty || redisKeyModels.count <= selectedRedisKeyIndex!) ? nil : redisKeyModels[selectedRedisKeyIndex!]
        }
    }
    
    var selectRedisKey:String? {
        selectRedisKeyModel?.id
    }
    
    private var sidebarHeader: some View {
        VStack(alignment: .center, spacing: 0) {
            VStack(alignment: .center, spacing: 2) {
                // redis search ...
                SearchBar(keywords: $scanModel.keywords, showFuzzy: false, placeholder: "Search keys...", action: onSearchKeyAction)
                    .padding(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                
                // redis key operate ...
                HStack {
                    IconButton(icon: "plus", name: "Add", action: onAddAction)
                    IconButton(icon: "trash", name: "Delete", disabled: selectedRedisKeyIndex == nil, isConfirm: true,
                               confirmTitle: String(format: Helps.DELETE_KEY_CONFIRM_TITLE, selectRedisKey ?? ""),
                               confirmMessage: String(format:Helps.DELETE_KEY_CONFIRM_MESSAGE, selectRedisKey ?? ""),
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
            MenuButton(label:
                        Label("", systemImage: "ellipsis.circle")
                        .labelStyle(IconOnlyLabelStyle())
            ){
                Button("Redis Info", action: onRedisInfoAction)
            }
            .frame(width:30)
            .menuButtonStyle(BorderlessPullDownMenuButtonStyle())
            
            MIcon(icon: "arrow.clockwise", fontSize: 12, action: onRefreshAction)
                .help(Helps.REFRESH)
            
            ScanBar(scanModel: scanModel, action: onQueryKeyPageAction, totalLabel: "dbsize")
        }
    }
    
    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            // header area
            sidebarHeader
            
            // list
            List(selection: $selectedRedisKeyIndex) {
                ForEach(redisKeyModels.indices, id:\.self) { index in
                    RedisKeyRowView(index: index, redisKeyModel: redisKeyModels[index])
                        .contextMenu {
                            Button("Rename", action: {
                                self.oldKeyIndex = index
                                self.renameModalVisible = true
                            })
                            MButton(text: "Delete Key", action: {try onDeleteConfirmAction(index)})
                        }
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                }
                
            }
            .listStyle(PlainListStyle())
            .frame(minWidth:150)
            .padding(.all, 0)
            
            // footer
//            SidebarFooter(page: page, pageAction: onQueryKeyPageAction)
            sidebarFoot
                .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 6))
            
        }
    }
    
    private var rightMainView: some View {
        VStack(alignment: .leading, spacing: 0){
            if selectRedisKeyModel == nil {
                if redisInfoVisible {
                    RedisInfoView()
                        .onDisappear {
                            self.redisInfoVisible = false
                        }
                } else {
                    EmptyView()
                }
            } else {
                RedisValueView(redisKeyModel: selectRedisKeyModel!)
            }
            Spacer()
        }
        .frame(minWidth: 600, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
        .layoutPriority(1)
    }
    
    var body: some View {
        HSplitView {
            // sidebar
            sidebar
            .padding(0)
            .frame(minWidth:240, idealWidth: 240, maxWidth: .infinity)
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
        let newRedisKeyModel = RedisKeyModel(key: "NEW_KEY_\(Date().millis)", type: RedisKeyTypeEnum.STRING.rawValue, isNew: true)
        
        self.redisKeyModels.insert(newRedisKeyModel, at: 0)
        self.selectedRedisKeyIndex = 0
    }
    
    func onRenameAction() throws -> Void {
        let renameKeyModel = redisKeyModels[oldKeyIndex!]
        let _ = redisInstanceModel.getClient().rename(renameKeyModel.key, newKey: newKeyName).done({r in
            if r {
                renameKeyModel.key = newKeyName
            }
        })
    }
    
    func onDeleteAction() throws -> Void {
        try deleteKey(selectedRedisKeyIndex!)
    }
    
    func onDeleteConfirmAction(_ index:Int) throws -> Void {
        globalContext.alertVisible = true
        globalContext.showSecondButton = true
        globalContext.primaryButtonText = "Delete"
        
        let item = redisKeyModels[index].key
        globalContext.alertTitle = String(format: Helps.DELETE_LIST_ITEM_CONFIRM_TITLE, item)
        globalContext.alertMessage = String(format:Helps.DELETE_LIST_ITEM_CONFIRM_MESSAGE, item)
        globalContext.primaryAction = {
            try deleteKey(index)
        }
    }
    
    func deleteKey(_ index:Int) throws -> Void {
        let redisKeyModel = self.redisKeyModels[index]
        let _ = redisInstanceModel.getClient().del(key: redisKeyModel.key).done({r in
            self.logger.info("on delete redis key: \(index), r:\(r)")
            self.redisKeyModels.remove(at: index)
        })
    }
    
    func onRefreshAction() -> Void {
        self.onSearchKeyAction()
    }
    
    func onRedisInfoAction() -> Void {
//        let _ = redisInstanceModel.getClient().info()
//        let window = NSWindow(
//            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
//            styleMask: [.titled, .closable, .resizable],
//               backing: .buffered,
//               defer: false
//        )
//        window.center()
//        window.setFrameAutosaveName("Redis Info")
//        window.title = "Redis Info"
//        window.toolbarStyle = .unifiedCompact
//        window.isReleasedWhenClosed = true
//        window.contentView = NSHostingView(rootView: RedisInfoView(redisInstanceModel: redisInstanceModel).frame(minWidth: 500, minHeight: 600))
//        window.makeKeyAndOrderFront(nil)
    
        self.selectedRedisKeyIndex = nil
        self.redisInfoVisible = true
    }
    
    func onSearchKeyAction() -> Void {
        scanModel.resetHead()
        onQueryKeyPageAction()
    }
    
    func onQueryKeyPageAction() -> Void {
        if !redisInstanceModel.isConnect || globalContext.loading {
            return
        }

        let promise = self.redisInstanceModel.getClient().pageKeys(scanModel)
            
        let _ = promise.done({ keysPage in
                self.redisKeyModels = keysPage
            })
    }
}



func testData() -> [RedisKeyModel] {
    let redisKeys:[RedisKeyModel] = [RedisKeyModel](repeating: RedisKeyModel(key: UUID().uuidString.lowercased(), type: "string"), count: 0)
    return redisKeys
}

struct RedisKeysList_Previews: PreviewProvider {
    static var redisInstanceModel:RedisInstanceModel = RedisInstanceModel(redisModel: RedisModel())
    static var previews: some View {
        RedisKeysListView(redisKeyModels: testData())
            .environmentObject(redisInstanceModel)
    }
}
