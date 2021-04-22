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
    
    let logger = Logger(label: "redis-key-list-view")
    
    var filteredRedisKeyModel: [RedisKeyModel] {
        redisKeyModels
    }
    var selectRedisKeyModel:RedisKeyModel? {
        (selectedRedisKeyIndex == nil || redisKeyModels.isEmpty || redisKeyModels.count <= selectedRedisKeyIndex!) ? nil : redisKeyModels[selectedRedisKeyIndex ?? 0]
    }
    
    var selectRedisKey:String? {
        selectRedisKeyModel?.id
    }
    
    var body: some View {
        HSplitView {
            VStack(alignment: .leading, spacing: 0) {
                // header area
                VStack(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/, spacing: 2) {
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
                    }
                }
                .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
                Rectangle().frame(height: 1)
                    .padding(.horizontal, 0).foregroundColor(Color.gray)
                
                List(selection: $selectedRedisKeyIndex) {
                    ForEach(filteredRedisKeyModel.indices, id:\.self) { index in
                        RedisKeyRowView(index: index, redisKeyModel: filteredRedisKeyModel[index])
                            //                            .listRowBackground((index  % 2 == 0) ? Color(.systemGray) : Color(.white))
                            //                            .background(index % 2 == 0 ? Color.gray.opacity(0.2) : Color.clear)
                            //                            .border(Color.blue, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
                            .listRowInsets(EdgeInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0)))
                    }
                    
                }
                
                .listStyle(PlainListStyle())
                .frame(minWidth:150)
                .padding(.all, 0)
                
                // footer
                PageBar(page: page, action: onQueryKeyPageAction)
                    .padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 6))
            }
            .padding(0)
            .frame(minWidth:240, idealWidth: 240, maxWidth: .infinity)
            .layoutPriority(0)
            
            VStack(alignment: .leading, spacing: 0){
                RedisValueView(redisKeyModel: selectRedisKeyModel)
                Spacer()
            }
            .frame(minWidth: 600, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
            .layoutPriority(1)
        }
        .onAppear{
            try? onQueryKeyPageAction()
        }
    }
    
    func onAddAction() -> Void {
        logger.info("on add redis key index: \(selectedRedisKeyIndex ?? -1)")
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
//    redisKeys.append(RedisKeyModel(id: UUID().uuidString, type: RedisKeyTypeEnum.HASH.rawValue))
//    redisKeys.append(RedisKeyModel(id: UUID().uuidString, type: RedisKeyTypeEnum.LIST.rawValue))
//    redisKeys.append(RedisKeyModel(id: UUID().uuidString, type: RedisKeyTypeEnum.SET.rawValue))
//    redisKeys.append(RedisKeyModel(id: UUID().uuidString, type: RedisKeyTypeEnum.ZSET.rawValue))
    
    
    
    return redisKeys
}

struct RedisKeysList_Previews: PreviewProvider {
    static var redisInstanceModel:RedisInstanceModel = RedisInstanceModel(redisModel: RedisModel())
    static var previews: some View {
        RedisKeysListView(redisKeyModels: testData())
            .environmentObject(redisInstanceModel)
    }
}
