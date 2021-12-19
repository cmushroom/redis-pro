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
    @State var text: String = ""
    
    @EnvironmentObject var redisKeyModel:RedisKeyModel
    @EnvironmentObject var redisInstanceModel:RedisInstanceModel
    var onSubmit: (() -> Void)?
    
    let logger = Logger(label: "redis-string-editor")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: MTheme.V_SPACING){
                // text editor
                MTextView(text: $text)
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
        .onChange(of: redisKeyModel.key, perform: { value in
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
//            DispatchQueue.main.async {
//                self.redisKeyModel.isNew = false
////                if self.redisKeyModel.isNew {
////                    self.redisKeyModel.isNew = false
////                }
//                print("......................... \(self.redisKeyModel)")
//            }
            
        }
    }
    
    func onRefreshAction() -> Void {
        if redisKeyModel.key.isEmpty {
            return
        }
        getValue(redisKeyModel)
        let _ = redisInstanceModel.getClient().ttl(redisKeyModel.key).done({r in
            self.redisKeyModel.ttl = r
        })
    }
    
    func onLoad() -> Void {
        if self.redisKeyModel.type != RedisKeyTypeEnum.STRING.rawValue {
            return
        }
        getValue(redisKeyModel)
    }
    
    func getValue(_ redisKeyModel:RedisKeyModel) -> Void {
        
        if redisKeyModel.key.isEmpty {
            return
        }
        if redisKeyModel.isNew {
            text = ""
        } else {
            let _ = redisInstanceModel.getClient().get(key: redisKeyModel.key).done({r in
                self.text = r
            })
        }
    }
}

//struct StringEditView_Previews: PreviewProvider {
//    static var redisKeyModel:RedisKeyModel = RedisKeyModel(key: "tes", type: "string")
//    static var previews: some View {
//        StringEditorView(redisKeyModel: redisKeyModel)
//    }
//}
