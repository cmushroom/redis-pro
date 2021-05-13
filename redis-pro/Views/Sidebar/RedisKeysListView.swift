//
//  RedisKeysList.swift
//  redis-pro
//
//  Created by chengpan on 2021/4/4.
//

import SwiftUI
import Logging

struct RedisKeysListView: View {
    @EnvironmentObject var redisInstanceModel:RedisInstanceModel
    @State var redisKeyModels:[RedisKeyModel] = testData()
    @State var selectedRedisKeyIndex:Int?
    @State var keywords:String = ""
    @StateObject var page:Page = Page()
    @State var addKeyModalVisible:Bool = false
    @State var newRedisKeyModel:RedisKeyModel = RedisKeyModel(key: "", type: RedisKeyTypeEnum.STRING.rawValue)
    
    let logger = Logger(label: "redis-key-list-view")
    
    var filteredRedisKeyModel: [RedisKeyModel] {
        redisKeyModels
    }
    var selectRedisKeyModel:RedisKeyModel? {
        get {
            if selectedRedisKeyIndex == nil {
                return nil
            }
            if selectedRedisKeyIndex == -1 {
                return RedisKeyModel(key: "", type: RedisKeyTypeEnum.STRING.rawValue, isNew: true)
            }
            
            return (selectedRedisKeyIndex == nil || redisKeyModels.isEmpty || redisKeyModels.count <= selectedRedisKeyIndex!) ? nil : redisKeyModels[selectedRedisKeyIndex ?? 0]
        }
        set {
            selectedRedisKeyIndex = -1
        }
    }
    
    var selectRedisKey:String? {
        selectRedisKeyModel?.id
    }
    
    private var header: some View {
        VStack(alignment: .center, spacing: 0) {
            VStack(alignment: .center, spacing: 2) {
                // redis search ...
                SearchBar(keywords: $keywords, showFuzzy: false, placeholder: "Search keys...", action: onQueryKeyPageAction)
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
    
    var body: some View {
        HSplitView {
            VStack(alignment: .leading, spacing: 0) {
                // header area
                header
                
                List(selection: $selectedRedisKeyIndex) {
                    ForEach(filteredRedisKeyModel.indices, id:\.self) { index in
                        RedisKeyRowView(index: index, redisKeyModel: filteredRedisKeyModel[index])
                            .listRowInsets(EdgeInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0)))
                    }
                    
                }
                .listStyle(PlainListStyle())
                .frame(minWidth:150)
                .padding(.all, 0)
                
                // footer
                SidebarFooter(page: page, pageAction: onQueryKeyPageAction)
                
            }
            .padding(0)
            .frame(minWidth:240, idealWidth: 240, maxWidth: .infinity)
            .layoutPriority(0)
            
            VStack(alignment: .leading, spacing: 0){
                RedisValueView(redisKeyModel: selectRedisKeyModel)
                
                Spacer()
            }
            // 这里会影响splitView 的自适应宽度, 必须加上
            .frame(minWidth: 600, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
            .layoutPriority(1)
        }
        .sheet(isPresented: $addKeyModalVisible, onDismiss: {
            logger.info("add key modal dismiss...")
        }) {
            ModalView("Add new key", action: onDoAddAction) {
                VStack(alignment:.leading, spacing: 8) {
                    FormItemText(label: "Key", placeholder: "New key", required: true, value: $newRedisKeyModel.key)
                    RedisKeyTypePicker(label: "Type", value: $newRedisKeyModel.type)
                }
                .frame(minWidth:400, minHeight:100)
            }
        }
        .onAppear{
            try? onQueryKeyPageAction()
        }
    }
    
    func onAddAction() -> Void {
        self.addKeyModalVisible = true
        self.newRedisKeyModel = RedisKeyModel(key: "", type: RedisKeyTypeEnum.STRING.rawValue)
//        logger.info("on add redis key index: \(selectedRedisKeyIndex ?? -1)")
//        selectedRedisKeyIndex = -1
    }
    
    func onDoAddAction() -> Void {
        logger.info("on do add new key action: \(newRedisKeyModel)")
//        self.addKeyModalVisible = true
//        self.newRedisKeyModel = RedisKeyModel(key: "", type: RedisKeyTypeEnum.STRING.rawValue)
//        logger.info("on add redis key index: \(selectedRedisKeyIndex ?? -1)")
//        selectedRedisKeyIndex = -1
    }
    
    func onDeleteAction() throws -> Void {
        logger.info("on delete redis key: \(selectRedisKey!)")
        let r:Int = try redisInstanceModel.getClient().del(key: selectRedisKey!)
        if r > 0 {
            if let index = redisKeyModels.firstIndex(where: { (e) -> Bool in
                return e.id == selectRedisKey
            }) {
                redisKeyModels.remove(at: index)
            }
        }
    }
    
    func onRefreshAction() -> Void {
        page.firstPage()
        try? onQueryKeyPageAction()
    }
    
    func onQueryKeyPageAction() throws -> Void {
        if !redisInstanceModel.isConnect {
            return
        }
        let keysPage = try redisInstanceModel.getClient().pageKeys(page: page, keywords: keywords)
        logger.info("query keys page, keys: \(keysPage), page: \(String(describing: page))")
        redisKeyModels = keysPage
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
