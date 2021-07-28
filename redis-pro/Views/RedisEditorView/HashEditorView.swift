//
//  KeyValueRowEditorView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/9.
//

import SwiftUI
import Logging
import PromiseKit

struct HashEditorView: View {
    @EnvironmentObject var redisInstanceModel:RedisInstanceModel
    @ObservedObject var redisKeyModel:RedisKeyModel
    @StateObject private var page:ScanModel = ScanModel()
    
    @State private var datasource:[Any] = [RedisHashEntryModel]()
    @State private var selectIndex:Int?
    @State private var refresh:Int = 0
    
    @State private var editModalVisible:Bool = false
    @State private var editNewField:Bool = false
    @State private var editIndex:Int = 0
    @State private var editField:String = ""
    @State private var editValue:String = ""
    
    private var selectField:String {
        selectIndex == nil ? "" : (datasource[selectIndex!] as! RedisHashEntryModel).field
    }
    
    var delButtonDisabled:Bool {
        datasource.count <= 0 || selectIndex == nil
    }
    
    let logger = Logger(label: "redis-hash-editor")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center , spacing: 4) {
                IconButton(icon: "plus", name: "Add", action: onAddFieldAction)
                IconButton(icon: "trash", name: "Delete", disabled:delButtonDisabled,
                           action: onDeleteAction)
                
                SearchBar(keywords: $page.keywords, placeholder: "Search field...", action: onQueryField)
                
                Spacer()
                ScanBar(scanModel:page, action: onPageAction)
            }
            .padding(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
            
            HashEntryTable(datasource: $datasource, selectRowIndex: $selectIndex, refresh: refresh
                           , deleteAction: { index in
                            onDeleteIndexAction(index)
                           }
                           , editAction: { index in
                            onEditIndexAction(index)
                           })
            
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
    
    // add and update
    func onAddFieldAction() throws -> Void {
        editNewField = true
        editIndex = -1
        editField = ""
        editValue = ""
        editModalVisible = true
    }
    
    func onEditIndexAction(_ index:Int) -> Void {
        let entry:RedisHashEntryModel = self.datasource[index] as! RedisHashEntryModel
        let field = entry.field
        
        editNewField = false
        editIndex = index
        editField = field
        editValue = entry.value
        editModalVisible = true
    }

    func onSaveFieldAction() throws -> Void {
        let _ = redisInstanceModel.getClient().hset(redisKeyModel.key, field: editField, value: editValue).done({ _ in
            
            if self.redisKeyModel.isNew {
                self.redisKeyModel.isNew = false
            }
            logger.info("redis hset success, update field list")
            
            if editIndex == -1 {
                self.datasource.insert(RedisHashEntryModel(field: editField, value: editValue), at: 0)
            } else {
                (self.datasource[editIndex] as! RedisHashEntryModel).value = editValue
                self.refresh += 1
            }
            
            
        })
    }
    
    
    func onQueryField() throws -> Void {
        page.reset()
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
            self.datasource = res
            self.selectIndex = res.count > 0 ? 0 : nil
        })
    }
    
    func ttl(_ redisKeyModel:RedisKeyModel) throws -> Void {
        let _  = redisInstanceModel.getClient().ttl(key: redisKeyModel.key).done({r in
            redisKeyModel.ttl = r
        })
    }
    
    // delete
    func onDeleteIndexAction(_ index:Int) -> Void {
        let entry:RedisHashEntryModel = self.datasource[index] as! RedisHashEntryModel
        let field = entry.field
        MAlert.confirm(String(format: Helps.DELETE_HASH_FIELD_CONFIRM_TITLE, field), message: String(format:Helps.DELETE_HASH_FIELD_CONFIRM_MESSAGE, field), primaryButton: "Delete", primaryAction: {
            let _ = deleteField(field).done({_ in
                self.datasource.remove(at: index)
            })
        })
    }
    
    func onDeleteAction() throws -> Void {
        onDeleteIndexAction(selectIndex!)
    }
    
    func deleteField(_ field:String) -> Promise<Int> {
        logger.info("delete hash field: \(field)")
        return redisInstanceModel.getClient().hdel(redisKeyModel.key, field: field)
    }
}


struct KeyValueRowEditorView_Previews: PreviewProvider {
    static var redisKeyModel:RedisKeyModel = RedisKeyModel(key: "tes", type: "string")
    static var previews: some View {
        HashEditorView(redisKeyModel: redisKeyModel)
    }
}
