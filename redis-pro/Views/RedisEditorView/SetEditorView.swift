//
//  ListEditorView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/30.
//

import SwiftUI
import Logging

struct SetEditorView: View {
    var onSubmit: (() -> Void)?
    
    @State private var list:[String] = [String]()
    @State private var selectIndex:Int?
    
    @EnvironmentObject var redisInstanceModel:RedisInstanceModel
    @EnvironmentObject var redisKeyModel:RedisKeyModel
    @StateObject private var page:Page = Page()
    
    @State private var editModalVisible:Bool = false
    @State private var editIndex:Int = 0
    @State private var editValue:String = ""
    
    
    var delButtonDisabled:Bool {
        list.count <= 0 || selectIndex == nil
    }
    
    let logger = Logger(label: "redis-set-editor")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center , spacing: 4) {
                IconButton(icon: "plus", name: "Add", action: onAddAction)
                IconButton(icon: "trash", name: "Delete", disabled:delButtonDisabled,
                           action: onDeleteAction)
                SearchBar(keywords: $page.keywords, placeholder: "Search set...", onCommit: onQueryField)
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
            ModalView("Edit set element", action: onUpdateItemAction) {
                VStack(alignment:.leading, spacing: MTheme.V_SPACING) {
                    FormItemTextArea(label: "Value", placeholder: "value", value: $editValue)
                }
            }
        }
        .onChange(of: redisKeyModel.id, perform: { value in
            logger.info("redis set value editor view change \(value)")
            onLoad()
        })
        .onAppear {
            logger.info("redis set value editor view init...")
            onLoad()
        }
    }

    
    func onAddAction() throws -> Void {
        editModalVisible = true
        editIndex = -1
        editValue = ""
    }
    
    func onEditAction(_ index:Int) -> Void {
        editModalVisible = true
        editIndex = index
        editValue = list[index]
    }
    
    func onUpdateItemAction() throws -> Void {
        Task {
            if editIndex == -1 {
                let r = await redisInstanceModel.getClient().sadd(redisKeyModel.key, ele: editValue)
                if r > 0 {
                    self.onSubmit?()
                    try onRefreshAction()
                }
                
            } else {
                let fromValue = self.list[self.editIndex]
                let r = await redisInstanceModel.getClient().supdate(redisKeyModel.key, from: fromValue, to: editValue )
                if r > 0 {
                    self.logger.info("redis set update success, update list")
                    self.list[editIndex] = editValue
                }
            }
        }
    }
    

    
    func onSubmitAction() throws -> Void {
        logger.info("redis hash value editor on submit")
        Task {
            let _ = await redisInstanceModel.getClient().expire(redisKeyModel.key, seconds: redisKeyModel.ttl)
        }
    }
    
    func onRefreshAction() throws -> Void {
        page.reset()
        queryPage(redisKeyModel)
        Task {
            await ttl(redisKeyModel)
        }
    }
    
    func onQueryField() -> Void {
        page.reset()
        queryPage(redisKeyModel)
    }
    
    func onPageAction() -> Void {
        queryPage(redisKeyModel)
    }
    
    func onLoad() -> Void {
        
        if  redisKeyModel.type != RedisKeyTypeEnum.SET.rawValue {
            return
        }
    
        page.reset()
        queryPage(redisKeyModel)
    }
    
    func queryPage(_ redisKeyModel:RedisKeyModel) -> Void {
        
        if redisKeyModel.isNew {
            return
        }
        
        Task {
            let res = await redisInstanceModel.getClient().pageSet(redisKeyModel.key, page: page)
            list = res.map{ $0 ?? ""}
            self.selectIndex = res.count > 0 ? 0 : nil
        }
    }
    
    func ttl(_ redisKeyModel:RedisKeyModel) async -> Void {
        let r = await redisInstanceModel.getClient().ttl(redisKeyModel.key)
        self.redisKeyModel.ttl = r
    }
    
    
    // delete
    func onDeleteAction() throws -> Void {
        onDeleteConfirmAction(selectIndex!)
    }
    
    func onDeleteConfirmAction(_ index:Int) -> Void {
        let item = list[index]
        
        MAlert.confirm(String(format: Helps.DELETE_LIST_ITEM_CONFIRM_TITLE, item), message: String(format:Helps.DELETE_LIST_ITEM_CONFIRM_MESSAGE, item), primaryButton: "Delete", primaryAction: {
            deleteEle(index)
        })
    }
    
    func deleteEle(_ index:Int) -> Void {
        logger.info("delete set item, index: \(index)")
        let ele = list[index]
        Task {
        let r = await redisInstanceModel.getClient().srem(redisKeyModel.key, ele: ele)
        if r > 0 {
            self.list.remove(at: index)
        }
        }
    }
}

//struct SetEditorView_Previews: PreviewProvider {
//    static var redisKeyModel:RedisKeyModel = RedisKeyModel(key: "tes", type: "string")
//    static var previews: some View {
//        SetEditorView(redisKeyModel: redisKeyModel)
//    }
//}
