//
//  KeyValueRowEditorView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/9.
//

import SwiftUI
import Logging

struct HashEditorView: View {
    var onSubmit: (() -> Void)?
    
    @EnvironmentObject var redisInstanceModel:RedisInstanceModel
    @EnvironmentObject var redisKeyModel:RedisKeyModel
    @StateObject private var page:ScanModel = ScanModel()
    
    @State private var datasource:[Any] = [RedisHashEntryModel]()
    @State private var selectIndex:Int = -1
    
    @State private var editModalVisible:Bool = false
    @State private var editIndex:Int = -1
    @StateObject private var editEntry = RedisHashEntryModel()
    
    
    private var delButtonDisabled:Bool {
        datasource.count <= 0 || selectIndex == -1
    }
    
    let logger = Logger(label: "redis-hash-editor")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center , spacing: 4) {
                IconButton(icon: "plus", name: "Add", action: {showEditModel(-1)})
                IconButton(icon: "trash", name: "Delete", disabled:delButtonDisabled,
                           action: onDeleteAction)
                
                SearchBar(keywords: $page.keywords, placeholder: "Search field...", onCommit: onQueryField)
                
                Spacer()
                ScanBar(scanModel:page, action: onPageAction)
            }
            .padding(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
            
            HashEntryTable(datasource: $datasource, selectRowIndex: $selectIndex
                           , deleteAction: { index in
                onDeleteIndexAction(index)
            }
                           , editAction: { index in
                showEditModel(index)
            }
            )
            // footer
            HStack(alignment: .center, spacing: 4) {
                Spacer()
                IconButton(icon: "arrow.clockwise", name: "Refresh", action: onRefreshAction)
                //                IconButton(icon: "checkmark", name: "Submit", confirmPrimaryButtonText: "Submit", action: onSubmitAction)
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
        .sheet(isPresented: $editModalVisible, onDismiss: {
        }) {
            ModalView("Edit hash entry", action: onSaveFieldAction) {
                VStack(alignment:.leading, spacing: 8) {
                    FormItemText(placeholder: "Field", value: $editEntry.field).disabled(!editEntry.isNew)
                    FormItemTextArea(placeholder: "Value", value: $editEntry.value)
                }
                .onAppear {
                    self.setEditForm()
                }
            }
        }
    }
    
}

// action
extension HashEditorView {
    func showEditModel(_ index:Int = -1) {
        self.editIndex = index
        self.editModalVisible = true
    }
    
    func setEditForm() {
        if editIndex < 0 {
            editEntry.field = ""
            editEntry.value = ""
            editEntry.isNew = true
        } else {
            let entry:RedisHashEntryModel = self.datasource[editIndex] as! RedisHashEntryModel
            editEntry.field = entry.field
            editEntry.value = entry.value
            editEntry.isNew = false
        }
    }
    
    func onSaveFieldAction() throws -> Void {
        Task {
            let r = await redisInstanceModel.getClient().hset(redisKeyModel.key, field: editEntry.field, value: editEntry.value)
            logger.info("redis hset success, update field list")
            if !r {
                return
            }
            
            self.onSubmit?()
            
            if editIndex == -1 {
                self.datasource.insert(RedisHashEntryModel(field: editEntry.field, value: editEntry.value), at: 0)
            } else {
                (self.datasource[editIndex] as! RedisHashEntryModel).value = editEntry.value
            }
        }
    }
    
    
    func onQueryField() -> Void {
        page.reset()
        queryHashPage(redisKeyModel)
    }
    
    func onSubmitAction() throws -> Void {
        logger.info("redis hash value editor on submit")
        Task {
            let _ = await redisInstanceModel.getClient().expire(redisKeyModel.key, seconds: redisKeyModel.ttl)
        }
    }
    
    func onRefreshAction() throws -> Void {
        if redisKeyModel.isNew {
            return
        }
        page.reset()
        queryHashPage(redisKeyModel)
        Task {
            await ttl()
        }
        
    }
    
    
    func onLoad() -> Void {
        if redisKeyModel.isNew || redisKeyModel.type != RedisKeyTypeEnum.HASH.rawValue {
            datasource.removeAll()
            return
        }
        
        queryHashPage(redisKeyModel)
    }
    
    func onPageAction() -> Void {
        queryHashPage(redisKeyModel)
    }
    
    func queryHashPage(_ redisKeyModel:RedisKeyModel) -> Void {
        if redisKeyModel.isNew {
            return
        }
        
        Task {
            let res = await redisInstanceModel.getClient().pageHash(redisKeyModel.key, page: page)
            self.datasource = res
            self.selectIndex = res.count > 0 ? 0 : -1
        }
    }
    
    func ttl() async -> Void {
        let r = await redisInstanceModel.getClient().ttl(redisKeyModel.key)
        self.redisKeyModel.ttl = r
    }
    
    // delete
    func onDeleteIndexAction(_ index:Int) -> Void {
        let entry:RedisHashEntryModel = self.datasource[index] as! RedisHashEntryModel
        let field = entry.field
        MAlert.confirm(String(format: Helps.DELETE_HASH_FIELD_CONFIRM_TITLE, field), message: String(format:Helps.DELETE_HASH_FIELD_CONFIRM_MESSAGE, field), primaryButton: "Delete", primaryAction: {
            Task {
                let r = await deleteField(field)
                if r > 0 {
                    self.datasource.remove(at: index)
                }
            }
        })
    }
    
    func onDeleteAction() throws -> Void {
        onDeleteIndexAction(selectIndex)
    }
    
    func deleteField(_ field:String) async -> Int {
        logger.info("delete hash field: \(field)")
        return await redisInstanceModel.getClient().hdel(redisKeyModel.key, field: field)
    }
}


//struct KeyValueRowEditorView_Previews: PreviewProvider {
//    static var redisKeyModel:RedisKeyModel = RedisKeyModel("tes", type: "string")
//    static var previews: some View {
//        HashEditorView(redisKeyModel: redisKeyModel)
//    }
//}
