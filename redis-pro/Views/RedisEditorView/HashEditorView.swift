//
//  KeyValueRowEditorView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/9.
//

import SwiftUI
import Logging

struct HashEditorView: View {
    @State var text:String = ""
    @State var hashMap:[String: String?] = ["":""]
    @State private var selectField:String?
    @State private var isEditing:Bool = false
    @EnvironmentObject var redisInstanceModel:RedisInstanceModel
    @EnvironmentObject var globalContext:GlobalContext
    @ObservedObject var redisKeyModel:RedisKeyModel
    @StateObject private var page:ScanModel = ScanModel()
    
    @State private var editModalVisible:Bool = false
    @State private var editNewField:Bool = false
    @State private var editField:String = ""
    @State private var editValue:String = ""
    
    
    var delButtonDisabled:Bool {
        selectField == nil
    }
    
    let logger = Logger(label: "redis-hash-editor")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center , spacing: 4) {
                IconButton(icon: "plus", name: "Add", action: onAddFieldAction)
                IconButton(icon: "trash", name: "Delete", disabled:delButtonDisabled,
                           isConfirm: true,
                           confirmTitle: String(format: Helps.DELETE_HASH_FIELD_CONFIRM_TITLE, selectField ?? ""),
                           confirmMessage: String(format:Helps.DELETE_HASH_FIELD_CONFIRM_MESSAGE, selectField ?? ""),
                           confirmPrimaryButtonText: "Delete",
                           action: onDeleteAction)
                
                SearchBar(keywords: $page.keywords, placeholder: "Search field...", action: onQueryField)
                
                Spacer()
                ScanBar(scanModel:page, action: onPageAction)
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
                        
                        ForEach(hashMap.sorted(by: {$0.0 < $1.0}), id: \.key) { key, value in
                            HStack {
                                Text(key)
                                    .onTapGesture(count:2) { //<- Needed to be first!
                                        print("doubletap")
                                    }.onTapGesture(count:1) {
                                        self.selectField = key
                                    }
                                    .font(.body)
                                    .frame(width: width0, alignment: .leading)
                                
                                Text(value ?? "")
                                    .font(.body)
                                    .multilineTextAlignment(.leading)
                                    .frame(width: width1, alignment: .leading)
                            }
                            .contextMenu {
                                Button(action: {
                                    editModalVisible = true
                                    editNewField = false
                                    editField = key
                                    editValue = value ?? ""
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
//                IconButton(icon: "checkmark", name: "Submit", confirmPrimaryButtonText: "Submit", action: onSubmitAction)
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
        .sheet(isPresented: $editModalVisible, onDismiss: {
        }) {
            ModalView("Edit field", action: onSaveFieldAction) {
                VStack(alignment:.leading, spacing: 8) {
                    FormItemText(label: "Field", placeholder: "Field", value: $editField, disabled: !editNewField)
                    FormItemTextArea(label: "Value", placeholder: "Value", value: $editValue)
                }
                .frame(minWidth:500, minHeight:300)
            }
            .onAppear {
                // 弹窗弹出后再次触发是否可以编辑，才能正常生效
                if self.editNewField {
                    self.editNewField.toggle()
                    self.editNewField.toggle()
                }
            }
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
    
    
    func onSaveFieldAction() throws -> Void {
        let _ = redisInstanceModel.getClient().hset(redisKeyModel.key, field: editField, value: editValue).done({ _ in
            
            if self.redisKeyModel.isNew {
                self.redisKeyModel.isNew = false
            }
            logger.info("redis hset success, update field list")
            
            self.onLoad(redisKeyModel)
        
        })
//        hashMap.updateValue(editValue, forKey: editField)
        
    }
    
    
    func onAddFieldAction() throws -> Void {
        editModalVisible = true
        editNewField = true
        editField = ""
        editValue = ""
    }
    
    func onDeleteAction() throws -> Void {
        try deleteField(selectField!)
    }
    func onQueryField() throws -> Void {
        page.resetHead()
        queryHashPage(redisKeyModel)
    }
    
    func onSubmitAction() throws -> Void {
        logger.info("redis hash value editor on submit")
        let _ = redisInstanceModel.getClient().expire(redisKeyModel.key, seconds: redisKeyModel.ttl)
    }
    
    func onRefreshAction() throws -> Void {
        queryHashPage(redisKeyModel)
        try ttl(redisKeyModel)
    }
    
    
    func onLoad(_ redisKeyModel:RedisKeyModel) -> Void {
        queryHashPage(redisKeyModel)
    }
    
    func onPageAction() -> Void {
        queryHashPage(redisKeyModel)
    }
    
    func queryHashPage(_ redisKeyModel:RedisKeyModel) -> Void {
        let _ = redisInstanceModel.getClient().pageHash(redisKeyModel, page: page).done({res in
            self.hashMap = res
        })
    }
    
    func ttl(_ redisKeyModel:RedisKeyModel) throws -> Void {
        redisKeyModel.ttl = try redisInstanceModel.getClient().ttl(key: redisKeyModel.key)
    }
    
    func deleteField(_ field:String) throws -> Void {
        logger.info("delete hash field: \(field)")
        let _ = redisInstanceModel.getClient().hdel(redisKeyModel.key, field: field).done({r in
            if r > 0 {
                self.hashMap.removeValue(forKey: field)
            }
        })
    }
}


struct KeyValueRowEditorView_Previews: PreviewProvider {
    static var redisKeyModel:RedisKeyModel = RedisKeyModel(key: "tes", type: "string")
    static var previews: some View {
        HashEditorView(redisKeyModel: redisKeyModel)
    }
}
