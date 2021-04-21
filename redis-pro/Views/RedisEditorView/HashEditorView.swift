//
//  HashEditView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/9.
//

import SwiftUI
import Logging

struct HashEditorView: View {
    @State var hash: Any?
    @State var editing:Bool = false
    @ObservedObject var redisKeyModel:RedisKeyModel
    @EnvironmentObject var redisInstanceModel:RedisInstanceModel
    @EnvironmentObject var globalContext:GlobalContext
    @ObservedObject var page:Page = Page()
    
    let logger = Logger(label: "hash-editor-view")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4){
                // label
                Text("String value:")
                    .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
                
            }
            .background(Color.white)
            
            // footer
            HStack(alignment: .center, spacing: 4) {
                Spacer()
                MButton(text: "Submit", action: onSubmitAction)
            }
            .padding(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
        }
        .onChange(of: redisKeyModel, perform: { value in
            logger.info("redis string value editor view change \(value)")
            onLoad(value)
        })
        .onAppear {
            logger.info("redis string value editor view init...")
            onLoad(redisKeyModel)
        }
        
    }
    
    
    func onSubmitAction() throws -> Void {
        logger.info("redis string value editor on submit")
//        try redisInstanceModel.getClient().set(redisKeyModel.key, value: text, ex: redisKeyModel.ttl)
    }
    
    func onRefreshAction() throws -> Void {
        try getValue(redisKeyModel)
        try ttl(redisKeyModel)
    }
    
    func onLoad(_ redisKeyModel:RedisKeyModel) -> Void {
        do {
            try getValue(redisKeyModel)
        } catch {
            logger.error("on string editor view load query redis key error:\(error)")
            globalContext.showError(error)
        }
    }
    
    func getValue(_ redisKeyModel:RedisKeyModel) throws -> Void {
//        text = try redisInstanceModel.getClient().pageHashEntry(redisKeyModel.key, page: page)
    }
    
    func ttl(_ redisKeyModel:RedisKeyModel) throws -> Void {
        redisKeyModel.ttl = try redisInstanceModel.getClient().ttl(key: redisKeyModel.key)
    }
}

struct HashEditView_Previews: PreviewProvider {
    static var previews: some View {
        HashEditorView(redisKeyModel: RedisKeyModel(key: "test", type: RedisKeyTypeEnum.STRING.rawValue))
    }
}
