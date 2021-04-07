//
//  RedisKeysList.swift
//  redis-pro
//
//  Created by chengpan on 2021/4/4.
//

import SwiftUI

struct RedisKeysListView: View {
    var redisKeyModels:[RedisKeyModel] = testData()
    @State var selectedRedisKeyIndex:Int?
    @State var keywords:String = ""
    @State private var pageSize:Int = 50
    
    var filteredRedisKeyModel: [RedisKeyModel] {
        redisKeyModels
    }
    var selectRedisKeyModel:RedisKeyModel {
        redisKeyModels[selectedRedisKeyIndex ?? 0]
    }
    
    var body: some View {
        HSplitView {
            VStack(alignment: .leading,
                   spacing: 0) {
                // header area
                VStack(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/, spacing: 2) {
                    // redis search ...
                    RedisKeySearchRowView(value: $keywords)
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
                
                List(selection: $selectedRedisKeyIndex) {
                    ForEach(filteredRedisKeyModel.indices, id:\.self) { index in
                        RedisKeyRowView(index: index, redisKeyModel: filteredRedisKeyModel[index])
                            //                            .listRowBackground((index  % 2 == 0) ? Color(.systemGray) : Color(.white))
                            //                            .background(index % 2 == 0 ? Color.gray.opacity(0.2) : Color.clear)
                            //                            .border(Color.blue, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
                            .listRowInsets(EdgeInsets(.init(top: 2, leading: 0, bottom: 2, trailing: 0)))
//                            .onTapGesture {
//                                print("selection \(selectedRedisKeyIndex ?? 0)")
//                            }
                    }
                    
                }
                
                
                .listStyle(PlainListStyle())
                .frame(minWidth:220)
                .padding(.all, 0)
                
                // footer
                HStack {
                    Text("Keys:123")
                        .font(.footnote)
                        .padding(.leading, 4.0)
                        
                    Spacer()
                    Picker("", selection: $pageSize) {
                        Text("50").tag(50)
                        Text("100").tag(100)
                        Text("200").tag(200)
                        Text("500").tag(500)
                    }
                    .frame(width: 70)
                    HStack {
                        MIcon(icon: "chevron.left").disabled(true)
                        Text("1/100000")
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                        MIcon(icon: "chevron.right")
                    }
                }
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
        }
    }
    
    func onAddAction() -> Void {
        logger.info("on add redis key index: \(selectedRedisKeyIndex ?? -1)")
    }
    func onDeleteAction() -> Void {
        logger.info("on delete redis key index: \(selectedRedisKeyIndex ?? -1)")
    }

}



func testData() -> [RedisKeyModel] {
    var redisKeys:[RedisKeyModel] = [RedisKeyModel](repeating: RedisKeyModel(id: UUID().uuidString.lowercased(), type: "string"), count: 50)
    redisKeys.append(RedisKeyModel(id: UUID().uuidString, type: RedisKeyTypeEnum.HASH.rawValue))
    redisKeys.append(RedisKeyModel(id: UUID().uuidString, type: RedisKeyTypeEnum.LIST.rawValue))
    redisKeys.append(RedisKeyModel(id: UUID().uuidString, type: RedisKeyTypeEnum.SET.rawValue))
    redisKeys.append(RedisKeyModel(id: UUID().uuidString, type: RedisKeyTypeEnum.ZSET.rawValue))
    
    
    return redisKeys
}

struct RedisKeysList_Previews: PreviewProvider {
    static var previews: some View {
        RedisKeysListView(redisKeyModels: testData(), selectedRedisKeyIndex: 0)
    }
}
