//
//  ListEditorView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/30.
//

import SwiftUI
import Logging

struct ListEditorView: View {
    @State var text:String = ""
    @State var list:[String] = [String]()
    @State private var selectIndex:Int?
    @State private var isEditing:Bool = false
    @EnvironmentObject var redisInstanceModel:RedisInstanceModel
    @EnvironmentObject var globalContext:GlobalContext
    @ObservedObject var redisKeyModel:RedisKeyModel
    @StateObject private var page:Page = Page()
    
    @State private var editModalVisible:Bool = false
    @State private var editNewField:Bool = false
    @State private var editIndex:Int = 0
    @State private var editValue:String = ""
    
    
    var delButtonDisabled:Bool {
        selectIndex == nil
    }
    
    var selectValue:String? {
        selectIndex == nil ? nil : list[selectIndex!]
    }
    
    let logger = Logger(label: "redis-list-editor")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center , spacing: 4) {
                IconButton(icon: "plus", name: "Add", action: onAddFieldAction)
                IconButton(icon: "trash", name: "Delete", disabled:delButtonDisabled,
                           isConfirm: true,
                           confirmTitle: String(format: Helps.DELETE_LIST_ITEM_CONFIRM_TITLE, selectValue ?? ""),
                           confirmMessage: String(format:Helps.DELETE_LIST_ITEM_CONFIRM_MESSAGE, selectValue ?? ""),
                           confirmPrimaryButtonText: "Delete",
                           action: onDeleteAction)
                
                SearchBar(keywords: $page.keywords, placeholder: "Search field...", action: onQueryField)
                
                Spacer()
                PageBar(page:page)
            }
            .padding(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
            
            List(selection: $selectIndex) {
                ForEach(0..<list.count) { index in
                    HStack {
                        Text(list[index])
                            .font(.body)
                            .multilineTextAlignment(.leading)
                            .frame(alignment: .leading)
                    }
                    .contextMenu {
                        Button(action: {
                            editModalVisible = true
                            editNewField = false
                            editIndex = index
                            editValue = list[index]
                        }){
                            Text("Edit")
                        }
                        Button(action: {
                            onDeleteConfirmAction(field: "")
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
            .listStyle(PlainListStyle())
            .padding(.all, 0)
            
            // footer
            HStack(alignment: .center, spacing: 4) {
                Spacer()
                IconButton(icon: "arrow.clockwise", name: "Refresh", action: onRefreshAction)
                IconButton(icon: "checkmark", name: "Submit", confirmPrimaryButtonText: "Submit", action: onSubmitAction)
            }
            .padding(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
        }
        .sheet(isPresented: $editModalVisible, onDismiss: {
            print("on dismiss")
        }) {
            ModalView("Update field", action: onSaveFieldAction) {
                VStack(alignment:.leading, spacing: 8) {
                    FormItemTextArea(label: "", placeholder: "value", value: $editValue)
                }
                .frame(minWidth:500, minHeight:300)
            }
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
        globalContext.alertTitle = String(format: Helps.DELETE_LIST_ITEM_CONFIRM_TITLE, field)
        globalContext.alertMessage = String(format:Helps.DELETE_LIST_ITEM_CONFIRM_MESSAGE, field)
        globalContext.primaryAction = {
            try deleteField(field)
        }
        
    }
    
    
    func onSaveFieldAction() throws -> Void {
//        let _ = try redisInstanceModel.getClient().hset(redisKeyModel.key, field: editField, value: editValue)
        logger.info("redis hset success, update field list")
//        hashMap.updateValue(editValue, forKey: editField)
    }
    
    
    func onAddFieldAction() throws -> Void {
        editModalVisible = true
        editNewField = true
        editIndex = -1
        editValue = ""
    }
    
    func onDeleteAction() throws -> Void {
//        try deleteField(selectField!)
    }
    
    func onQueryField() throws -> Void {
        try queryHashPage(redisKeyModel)
    }
    
    func onSubmitAction() throws -> Void {
        logger.info("redis hash value editor on submit")
        let _ = try redisInstanceModel.getClient().expire(redisKeyModel.key, seconds: redisKeyModel.ttl)
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
//        hashMap = try redisInstanceModel.getClient().pageHashEntry(redisKeyModel.key, page: page)
    }
    
    func ttl(_ redisKeyModel:RedisKeyModel) throws -> Void {
        redisKeyModel.ttl = try redisInstanceModel.getClient().ttl(key: redisKeyModel.key)
    }
    
    func deleteField(_ field:String) throws -> Void {
        logger.info("delete hash field: \(field)")
        let r = try redisInstanceModel.getClient().hdel(redisKeyModel.key, field: field)
        if r > 0 {
//            hashMap.removeValue(forKey: field)
        }
    }
}

struct ListEditorView_Previews: PreviewProvider {
    static var redisKeyModel:RedisKeyModel = RedisKeyModel(key: "tes", type: "string")
    static var previews: some View {
        ListEditorView(redisKeyModel: redisKeyModel)
    }
}
