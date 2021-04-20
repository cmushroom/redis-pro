//
//  StringEditView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/7.
//

import SwiftUI
import Logging

struct StringEditorView: View {
    @State var text: String = ""
    @State var editing:Bool = false
    @ObservedObject var redisKeyModel:RedisKeyModel
    @EnvironmentObject var redisInstanceModel:RedisInstanceModel
    @EnvironmentObject var globalContext:GlobalContext
    
    let logger = Logger(label: "redis-string-value-editor")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4){
                // label
                Text("String value:")
                    .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
                
                // text editor
                TextEditor(text: $text)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .padding(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                    .lineSpacing(1.5)
                    .disableAutocorrection(true)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .border(Color.gray.opacity(editing ? 0.6 : 0.3), width: 1)
                    .onHover { inside in
                        self.editing = inside
                    }
            }
            .background(Color.white)
            
            // footer
            HStack(alignment: .center, spacing: 4) {
                Spacer()
                IconButton(icon: "arrow.clockwise", name: "Refresh", action: onRefreshAction)
                IconButton(icon: "checkmark", name: "Submit", isConfirm: false, confirmTitle: "", confirmMessage: "", confirmPrimaryButtonText: "Submit", action: onSubmitAction)
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
        try redisInstanceModel.getClient().set(redisKeyModel.key, value: text, ex: redisKeyModel.ttl)
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
        text = try redisInstanceModel.getClient().get(key: redisKeyModel.key)
    }
    
    func ttl(_ redisKeyModel:RedisKeyModel) throws -> Void {
        redisKeyModel.ttl = try redisInstanceModel.getClient().ttl(key: redisKeyModel.key)
    }
}
struct StringEditView_Previews: PreviewProvider {
    static var redisKeyModel:RedisKeyModel = RedisKeyModel(key: "tes", type: "string")
    static var previews: some View {
        StringEditorView(redisKeyModel: redisKeyModel)
    }
}
