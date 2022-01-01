//
//  ListEditorView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/30.
//

import SwiftUI
import Logging

struct ListEditorView: View {
    var onSubmit: (() -> Void)?
    @State var text:String = ""
    @State var list:[String] = [String]()
    @State private var selectIndex:Int?
    @State private var isEditing:Bool = false
    @EnvironmentObject var redisInstanceModel:RedisInstanceModel
    @EnvironmentObject var globalContext:GlobalContext
    @EnvironmentObject var redisKeyModel:RedisKeyModel
    @StateObject private var page:Page = Page()
    
    @State private var editModalVisible:Bool = false
    @State private var editNewField:Bool = false
    @State private var editIndex:Int = 0
    @State private var editValue:String = ""
    
    var delButtonDisabled:Bool {
        list.count <= 0 || selectIndex == nil
    }
    
    var selectValue:String? {
        selectIndex == nil || selectIndex! >= list.count ? nil : list[selectIndex!]
    }
    
    let logger = Logger(label: "redis-list-editor")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center , spacing: 4) {
                IconButton(icon: "plus", name: "Add head", action: onLPushAction)
                IconButton(icon: "plus", name: "Add tail", action: onRPushAction)
                IconButton(icon: "trash", name: "Delete", disabled:delButtonDisabled,
                           isConfirm: true,
                           confirmTitle: String(format: Helps.DELETE_LIST_ITEM_CONFIRM_TITLE, selectValue ?? ""),
                           confirmMessage: String(format:Helps.DELETE_LIST_ITEM_CONFIRM_MESSAGE, selectValue ?? ""),
                           confirmPrimaryButtonText: "Delete",
                           action: onDeleteAction)
                
                Spacer()
                PageBar(page:page, action: onPageAction)
            }
            .padding(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
            
            ListTable(datasource: $list, selectRowIndex: $selectIndex
                      , deleteAction: { index in
                        onDeleteConfirmAction(index)
                      }, editAction: { index in
                        onEditAction(index)
                      })

            // footer
            HStack(alignment: .center, spacing: MTheme.H_SPACING) {
                Spacer()
                IconButton(icon: "arrow.clockwise", name: "Refresh", action: onRefreshAction)
            }
            .padding(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
        }
        .sheet(isPresented: $editModalVisible, onDismiss: {
            print("on dismiss")
        }) {
            ModalView("Edit item", action: onUpdateItemAction) {
                VStack(alignment:.leading, spacing: MTheme.V_SPACING) {
//                    FormItemTextArea(label: "", placeholder: "value", value: $editValue)
                    MTextView(text: $editValue)
                }
                
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
    
    func onEditAction(_ index:Int) -> Void {
        editNewField = false
        editIndex = index
        editValue = list[index]
        
        editModalVisible = true
    }
    
    func onDeleteConfirmAction(_ index:Int) -> Void {
        let item = list[index]
        
        globalContext.confirm(String(format: Helps.DELETE_LIST_ITEM_CONFIRM_TITLE, item), alertMessage: String(format:Helps.DELETE_LIST_ITEM_CONFIRM_MESSAGE, item)
                              , primaryAction: {
                                deleteField(index)
                            }
        , primaryButton: "Delete")
        
    }
    
    func onLPushAction() throws -> Void {
        editModalVisible = true
        editNewField = true
        editIndex = -1
        editValue = ""
    }
    
    func onRPushAction() throws -> Void {
        editModalVisible = true
        editNewField = true
        editIndex = -2
        editValue = ""
    }
    
    func onUpdateItemAction() throws -> Void {
        Task {
        if editIndex == -1 {
            let _ = await redisInstanceModel.getClient().lpush(redisKeyModel.key, value: editValue)
            self.onSubmit?()
            onRefreshAction()
            
        } else if editIndex == -2 {
            let _ = await redisInstanceModel.getClient().rpush(redisKeyModel.key, value: editValue)
            self.onSubmit?()
            onRefreshAction()
        } else {
            let index = (page.current - 1) * page.size + editIndex
            let _ = await redisInstanceModel.getClient().lset(redisKeyModel.key, index: index, value: editValue)
            logger.info("redis list set success, update list")
            list[editIndex] = editValue
        }
        }
    }
    
    func onDeleteAction() -> Void {
        deleteField(selectIndex!)
        onRefreshAction()
    }
    
    func onSubmitAction() -> Void {
        logger.info("redis hash value editor on submit")
        Task {
            let _ = await redisInstanceModel.getClient().expire(redisKeyModel.key, seconds: redisKeyModel.ttl)
        }
    }
    
    func onRefreshAction() -> Void {
        page.firstPage()
        
        Task {
            await queryPage(redisKeyModel)
            await ttl()
        }
        
    }
    
    
    func onPageAction() -> Void {
        Task {
            await queryPage(redisKeyModel)
        }
    }
    
    func onLoad(_ redisKeyModel:RedisKeyModel) -> Void {
        
        if redisKeyModel.type != RedisKeyTypeEnum.LIST.rawValue {
            return
        }
        
        Task {
            await queryPage(redisKeyModel)
        }
    }
    
    func queryPage(_ redisKeyModel:RedisKeyModel) async -> Void {
        if redisKeyModel.isNew {
            return
        }
        let res = await redisInstanceModel.getClient().pageList(redisKeyModel.key, page: page)
        self.list = res.map{ $0 ?? ""}
        self.selectIndex = res.count > 0 ? 0 : nil
        
    }
    
    func ttl() async -> Void {
        let r  = await redisInstanceModel.getClient().ttl(self.redisKeyModel.key)
        self.redisKeyModel.ttl = r
    }
    
    func deleteField(_ index:Int) -> Void {
        logger.info("delete list item, index: \(index)")
        Task {
            let r = await redisInstanceModel.getClient().ldel(redisKeyModel.key, index: index)
            if r > 0 {
                self.list.remove(at: index)
            }
        }
    }
}

//struct ListEditorView_Previews: PreviewProvider {
//    static var redisKeyModel:RedisKeyModel = RedisKeyModel(key: "tes", type: "string")
//    static var previews: some View {
//        ListEditorView(redisKeyModel: redisKeyModel)
//    }
//}
