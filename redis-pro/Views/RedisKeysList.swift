//
//  RedisKeysList.swift
//  redis-pro
//
//  Created by chengpan on 2021/4/4.
//

import SwiftUI

struct RedisKeysList: View {
    var redisKeyModels:[RedisKeyModel] = [RedisKeyModel](repeating: RedisKeyModel(id: UUID().uuidString, type: RedisKeyTypeEnum.HASH.rawValue), count: 1)
    @State var selectedRedisKeyId:String?
    @State var keywords:String = ""
    @State private var pageSize:Int = 50
    
    var filteredRedisKeyModel: [RedisKeyModel] {
        redisKeyModels
    }
    
    var body: some View {
        HSplitView {
            VStack(alignment: .leading,
                   spacing: 0) {
                // header area
                VStack(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/, spacing: 2) {
                    // redis search ...
                    RedisKeySearchRow(value: $keywords)
                        .frame(minWidth: 220)
                        .padding(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                    // redis key operate ...
                    HStack {
                        Button(action: onDeleteAction) {
                            HStack(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/, spacing: 2) {
                            Image(systemName: "plus")
                                .font(.system(size: 12.0))
                                .padding(0)
                            Text("Add")
                            }
                        }
                        .buttonStyle(BorderedButtonStyle())
                        Button(action: onDeleteAction) {
                            HStack(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/, spacing: 2) {
                            Image(systemName: "trash")
                                .font(.system(size: 10.0))
                                .padding(0)
                            Text("Delete")
                            }
                        }
                        .buttonStyle(BorderedButtonStyle())
                        Spacer()
                    }
                }
                .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
                Rectangle().frame(height: 1)
                    .padding(.horizontal, 0).foregroundColor(Color.gray)
                
                List(selection: $selectedRedisKeyId) {
                    ForEach(0..<filteredRedisKeyModel.count) { index in
                        RedisKeyRow(redisKeyModel: filteredRedisKeyModel[index])
                            .background(index % 2 == 0 ? Color.gray : Color.clear)
                            .listRowInsets(EdgeInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0)))
                        
                    }
                    
                }
                .listStyle(PlainListStyle())
                .frame(minWidth:220)
                .padding(.all, 0)
                
                // footer
                Picker("", selection: $pageSize) {
                    Text("50").tag(50)
                    Text("100").tag(100)
                    Text("200").tag(200)
                }
            }
            .padding(0)
            
            
            VStack{
                Spacer()
                HStack {
                    Spacer()
                    //                    LoginForm(redisModel: selectRedisModel)
                    Spacer()
                }
                Spacer()
            }
            .frame(minWidth: 500, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
        }
        .onAppear{
        }
    }
}

func onAddAction() -> Void {
    logger.info("on add redis key")
}
func onDeleteAction() -> Void {
    logger.info("on add redis key")
}


func testData() -> [RedisKeyModel] {
    var redisKeys:[RedisKeyModel] = [RedisKeyModel](repeating: RedisKeyModel(id: UUID().uuidString, type: RedisKeyTypeEnum.STRING.rawValue), count: 50)
    redisKeys.append(RedisKeyModel(id: UUID().uuidString, type: RedisKeyTypeEnum.HASH.rawValue))
    redisKeys.append(RedisKeyModel(id: UUID().uuidString, type: RedisKeyTypeEnum.LIST.rawValue))
    redisKeys.append(RedisKeyModel(id: UUID().uuidString, type: RedisKeyTypeEnum.SET.rawValue))
    redisKeys.append(RedisKeyModel(id: UUID().uuidString, type: RedisKeyTypeEnum.ZSET.rawValue))
    
    
    return redisKeys
}

struct RedisKeysList_Previews: PreviewProvider {
    static var previews: some View {
        RedisKeysList(redisKeyModels: testData(), selectedRedisKeyId: "")
    }
}
