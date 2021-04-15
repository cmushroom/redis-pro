//
//  RedisKeysList.swift
//  redis-pro
//
//  Created by chengpan on 2021/4/4.
//

import SwiftUI
import Logging

struct RedisKeysListView: View {
    var redisInstanceModel:RedisInstanceModel
    @State var redisKeyModels:[RedisKeyModel] = testData()
    @State var selectedRedisKeyIndex:Int?
    @State var keywords:String = ""
    @StateObject var page:Page = Page()
    
    let logger = Logger(label: "redis-key-list-view")
    
    var filteredRedisKeyModel: [RedisKeyModel] {
        redisKeyModels
    }
    var selectRedisKeyModel:RedisKeyModel {
        redisKeyModels[selectedRedisKeyIndex ?? 0]
    }
    
    var body: some View {
        HSplitView {
            VStack(alignment: .leading, spacing: 0) {
                // header area
                VStack(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/, spacing: 2) {
                    // redis search ...
                    SearchBar(keywords: $keywords, showFuzzy: true, placeholder: "Search keys...", action: onQueryKeyPageAction)
                        .frame(minWidth: 220)
                        .padding(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                    
                    // redis key operate ...
                    HStack {
                        IconButton(icon: "plus", name: "Add", action: onDeleteAction)
                        IconButton(icon: "trash", name: "Delete", action: onDeleteAction)
                        
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
                .frame(minWidth:220)
                .padding(.all, 0)
                
                // footer
                PageBar(page: page, action: onQueryKeyPageAction)
                    .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 8))
            }
            .padding(0)
            
            
            VStack(alignment: .leading, spacing: 0){
                RedisValueView(redisKeyModel: selectRedisKeyModel)
                Spacer()
            }
            .frame(minWidth: 500, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
        }
        .onAppear{
            //            redisInstanceModel.queryKeyPage(page: Page(), keywords: "")
        }
    }
    
    func onAddAction() -> Void {
        logger.info("on add redis key index: \(selectedRedisKeyIndex ?? -1)")
    }
    func onDeleteAction() -> Void {
        logger.info("on delete redis key index: \(selectedRedisKeyIndex ?? -1)")
    }
    
    func onQueryKeyPageAction() -> Void {
        do {
            let keysPage = try redisInstanceModel.getClient().pageKeys(page: page, keywords: keywords)
            logger.info("query keys page, keys: \(keysPage), page: \(String(describing: page))")
            redisKeyModels = keysPage
        } catch {
            redisInstanceModel.alertContext = AlertContext(true, msg: "scan redis keys error: \(error)")
        }
    }
}



func testData() -> [RedisKeyModel] {
    var redisKeys:[RedisKeyModel] = [RedisKeyModel](repeating: RedisKeyModel(id: UUID().uuidString.lowercased(), type: "string"), count: 1)
    redisKeys.append(RedisKeyModel(id: UUID().uuidString, type: RedisKeyTypeEnum.HASH.rawValue))
    redisKeys.append(RedisKeyModel(id: UUID().uuidString, type: RedisKeyTypeEnum.LIST.rawValue))
    redisKeys.append(RedisKeyModel(id: UUID().uuidString, type: RedisKeyTypeEnum.SET.rawValue))
    redisKeys.append(RedisKeyModel(id: UUID().uuidString, type: RedisKeyTypeEnum.ZSET.rawValue))
    
    
    
    return redisKeys
}

struct RedisKeysList_Previews: PreviewProvider {
    static var previews: some View {
        RedisKeysListView(redisInstanceModel: RedisInstanceModel(redisModel: RedisModel()), redisKeyModels: testData(), selectedRedisKeyIndex: 0)
    }
}
