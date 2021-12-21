//
//  StringEditView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/7.
//

import SwiftUI
import Logging
import SwiftyJSON
import Cocoa

struct StringEditorView: View {
    @State private var text: String = ""
    
    @EnvironmentObject var redisKeyModel:RedisKeyModel
    @EnvironmentObject var redisInstanceModel:RedisInstanceModel
    var onSubmit: (() -> Void)?
    
    let logger = Logger(label: "string-editor")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: MTheme.V_SPACING){
                // text editor
                MTextView(text: $text)
//                MTextEditor(text: $text)
            }
            .background(Color.init(NSColor.textBackgroundColor))

            // footer
            HStack(alignment: .center, spacing: MTheme.H_SPACING) {
                Spacer()
                MButton(text: "Json Format", action: onJsonFormat)
                IconButton(icon: "arrow.clockwise", name: "Refresh", action: onRefreshAction)
                IconButton(icon: "checkmark", name: "Submit", isConfirm: false, confirmTitle: "", confirmMessage: "", confirmPrimaryButtonText: "Submit", action: onSubmitAction)
            }
            .padding(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
        }
        .onChange(of: redisKeyModel.id, perform: { value in
            logger.info("redis string value editor view change \(value)")
            onLoad()
        })
        .onAppear {
            logger.info("redis string value editor view init...")
            onLoad()
        }
        
    }
    
    func onJsonFormat() throws -> Void {
        if text.count < 2 {
            return
        }
        let jsonObj = JSON(parseJSON: text)
        if jsonObj == JSON.null {
            throw BizError(message: "Format json error")
        }
        if let string = jsonObj.rawString() {
            self.text = string
        }
    }
    
    func onSubmitAction() -> Void {
        logger.info("redis string value editor on submit")
        Task {
            await redisInstanceModel.getClient().set(redisKeyModel.key, value: text, ex: redisKeyModel.ttl)
            self.onSubmit?()
        }
    }
    
    func onRefreshAction() -> Void {
        if redisKeyModel.key.isEmpty {
            return
        }
        Task {
            await getValue()
            let ttl = await redisInstanceModel.getClient().ttl(redisKeyModel.key)
            self.redisKeyModel.ttl = ttl
        }
    }
    
    func onLoad() -> Void {
        if self.redisKeyModel.isNew || self.redisKeyModel.type != RedisKeyTypeEnum.STRING.rawValue {
            text = ""
            return
        }
        Task {
            await getValue()
        }
    }
    
    func getValue() async -> Void {
        let r = await redisInstanceModel.getClient().get(redisKeyModel.key)
        self.text = r
    }
}

//struct StringEditView_Previews: PreviewProvider {
//    static var redisKeyModel:RedisKeyModel = RedisKeyModel(key: "tes", type: "string")
//    static var previews: some View {
//        StringEditorView(redisKeyModel: redisKeyModel)
//    }
//}
