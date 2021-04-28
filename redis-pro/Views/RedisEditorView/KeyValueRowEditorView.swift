//
//  KeyValueRowEditorView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/9.
//

import SwiftUI
import Logging

struct KeyValueRowEditorView: View {
    @State var text:String = ""
    @State var hashMap:[String: String?] = ["testesttesttesttesttesttesttesttesttesttesttestt":"234243242343"]
    @State var selectField:String?
    @State var isEditing:Bool = false
    @EnvironmentObject var redisInstanceModel:RedisInstanceModel
    @EnvironmentObject var globalContext:GlobalContext
    @ObservedObject var redisKeyModel:RedisKeyModel
    @StateObject var page:Page = Page()
    @State var focusKey = "14"
    
    
    var delButtonDisabled:Bool {
        selectField == nil
    }
    
    let logger = Logger(label: "redis-editor-kv")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center , spacing: 4) {
                IconButton(icon: "plus", name: "Add", action: onDeleteAction)
                IconButton(icon: "trash", name: "Delete", disabled:delButtonDisabled,
                           isConfirm: true,
                           confirmTitle: String(format: Helps.DELETE_HASH_FIELD_CONFIRM_TITLE, selectField ?? ""),
                           confirmMessage: String(format:Helps.DELETE_HASH_FIELD_CONFIRM_MESSAGE, selectField ?? ""),
                           confirmPrimaryButtonText: "Delete",
                           action: onDeleteAction)
                
                SearchBar(keywords: $page.keywords, placeholder: "Search field...", action: onQueryField)
                
                Spacer()
                PageBar(page:page)
            }
            .padding(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
            
            GeometryReader { geometry in
                let width0 = geometry.size.width/2
                let width1 = width0
                
                List(selection: $selectField) {
                    Section(header: HStack {
                        Text("Field")
                            .frame(width: width0, alignment: .leading)
                        Text("Value")
                            .frame(width: width1, alignment: .leading)
                            .padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 0))
                            .border(width:1, edges: [.leading], color: Color.gray)
                    }) {
                        
                        ForEach(Array(hashMap.keys), id:\.self) { key in
                            HStack {
                                Text(key)
                                    .onTapGesture(count:2) { //<- Needed to be first!
                                                        print("doubletap")
                                                    }.onTapGesture(count:1) {
                                                        self.selectField = key
                                                    }
                                    .font(.body)
                                    .frame(width: width0, alignment: .leading)
                                    
                                TextField("Line 1", text: $text)
                                    .focusable(key == focusKey, onFocusChange: {_ in
                                        print("focused \(key)")
                                    })
                                    .font(.body)
                                    .multilineTextAlignment(.leading)
                                    .frame(width: width1, alignment: .leading)
                            }
                            .contextMenu {
                                Button(action: {
                                    print("sdfdsfsdfd")
                                }){
                                    Text("Edit")
                                }
                                Button(action: {
                                    onDeleteConfirmAction(field: key)
                                }){
                                    Text("Delete")
                                }
                            }
                            .padding(EdgeInsets(top: 4, leading: 2, bottom: 4, trailing: 2))
                            .overlay(
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(Color.gray.opacity(0.1)),
                                alignment: .bottom
                            )
                            .listRowInsets(EdgeInsets())
                        }
                    }
                    .collapsible(false)
                    
                }
                .listStyle(PlainListStyle())
                .padding(.all, 0)
            }
            
            // footer
            HStack(alignment: .center, spacing: 4) {
                Spacer()
                IconButton(icon: "arrow.clockwise", name: "Refresh", action: onRefreshAction)
                IconButton(icon: "checkmark", name: "Submit", confirmPrimaryButtonText: "Submit", action: onSubmitAction)
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
    
    func onDeleteConfirmAction(field:String) -> Void {
        globalContext.alertVisible = true
        globalContext.showSecondButton = true
        globalContext.primaryButtonText = "Delete"
        globalContext.alertTitle = String(format: Helps.DELETE_HASH_FIELD_CONFIRM_TITLE, field)
        globalContext.alertMessage = String(format:Helps.DELETE_HASH_FIELD_CONFIRM_MESSAGE, field)
        globalContext.primaryAction = {
            try deleteField(field)
        }
        
    }
    
    func onDeleteAction() throws -> Void {
        try deleteField(selectField!)
    }
    func onQueryField() throws -> Void {
        try queryHashPage(redisKeyModel)
    }
    
    func onSubmitAction() throws -> Void {
        logger.info("redis string value editor on submit")
        //        try redisInstanceModel.getClient().set(redisKeyModel.key, value: text, ex: redisKeyModel.ttl)
    }
    
    func onRefreshAction() throws -> Void {
        try queryHashPage(redisKeyModel)
        try ttl(redisKeyModel)
    }
    
    func onLoad(_ redisKeyModel:RedisKeyModel) -> Void {
        do {
            try queryHashPage(redisKeyModel)
        } catch {
            logger.error("on string editor view load query redis hash error:\(error)")
            globalContext.showError(error)
        }
    }
    
    func queryHashPage(_ redisKeyModel:RedisKeyModel) throws -> Void {
        hashMap = try redisInstanceModel.getClient().pageHashEntry(redisKeyModel.key, page: page)
    }
    
    func ttl(_ redisKeyModel:RedisKeyModel) throws -> Void {
        redisKeyModel.ttl = try redisInstanceModel.getClient().ttl(key: redisKeyModel.key)
    }
    
    func deleteField(_ field:String) throws -> Void {
        logger.info("delete hash field: \(field)")
        let r = try redisInstanceModel.getClient().hdel(redisKeyModel.key, field: field)
        if r > 0 {
            hashMap.removeValue(forKey: field)
        }
    }
}

struct KeyValueRowEditorView_Previews: PreviewProvider {
    static var redisKeyModel:RedisKeyModel = RedisKeyModel(key: "tes", type: "string")
    static var previews: some View {
        KeyValueRowEditorView(redisKeyModel: redisKeyModel)
    }
}
