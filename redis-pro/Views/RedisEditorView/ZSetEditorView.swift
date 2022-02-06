//
//  ZSetEditorView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/5/7.
//

import SwiftUI
import Logging

struct ZSetEditorView: View {
    var onSubmit: (() -> Void)?
    @State private var datasource:[RedisZSetItemModel] = [RedisZSetItemModel]()
    @State private var selectIndex:Int?
    @State private var refresh:Int = 0
    @EnvironmentObject var redisInstanceModel:RedisInstanceModel
    @EnvironmentObject var redisKeyModel:RedisKeyModel
    @StateObject private var page:Page = Page()
    
    @State private var editModalVisible:Bool = false
    @State private var editIndex:Int = 0
    @State private var editValue:String = ""
    @State private var editScore:Double = 0
    
    var delButtonDisabled:Bool {
        datasource.count <= 0 || selectIndex == nil
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
            
            ZSetTable(datasource: $datasource, selectRowIndex: $selectIndex, refresh: refresh
                      , deleteAction: { index in
                onDeleteConfirmAction(index)
            }
                      , editAction: { index in
                onEditAction(index)
            })
            
            // footer
            HStack(alignment: .center, spacing: 4) {
                Spacer()
                IconButton(icon: "arrow.clockwise", name: "Refresh", action: onRefreshAction)
                //                IconButton(icon: "checkmark", name: "Submit", confirmPrimaryButtonText: "Submit", action: onSubmitAction)
            }
            .padding(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
        }
        .sheet(isPresented: $editModalVisible, onDismiss: {
            print("on dismiss")
        }) {
            ModalView("Edit zset element", action: onUpdateItemAction) {
                VStack(alignment:.leading, spacing: 8) {
                    //                    TextField("", value: $editScore, formatter: NumberFormatter())
                    FormItemDouble(label: "Score", placeholder: "score", value: $editScore)
                    FormItemTextArea(label: "Value", placeholder: "value", value: $editValue)
                }
            }
        }
        .onChange(of: redisKeyModel, perform: { value in
            logger.info("redis zset value editor view change \(value)")
            onLoad(value)
        })
        .onAppear {
            logger.info("redis zset value editor view init...")
            onLoad(redisKeyModel)
        }
        
    }
    
    func onAddAction() throws -> Void {
        editModalVisible = true
        editIndex = -1
        editValue = ""
        editScore = 0
    }
    
    func onEditAction(_ index:Int) -> Void {
        editModalVisible = true
        editIndex = index
        editValue = self.datasource[index].value
        editScore = Double(self.datasource[index].score) ?? 0
    }
    
    func onUpdateItemAction() throws -> Void {
        let score:Double = editScore
        Task {
            if editIndex == -1 {
                let r = await redisInstanceModel.getClient().zadd(redisKeyModel.key, score: score, ele: editValue)
                if r {
                    self.onSubmit?()
                    self.datasource.insert(RedisZSetItemModel(value: editValue, score: NumberHelper.formatDouble(editScore)), at: 0)
                }
            } else {
                let editEle = datasource[editIndex]
                let r = await redisInstanceModel.getClient().zupdate(redisKeyModel.key, from: editEle.value, to: editValue, score: score )
                if r {
                    self.logger.info("redis zset update success, update list")
                    
                    self.datasource[editIndex].value = editValue
                    self.datasource[editIndex].score = NumberHelper.formatDouble(editScore)
                    self.refresh += 1
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
    
    func onLoad(_ redisKeyModel:RedisKeyModel) -> Void {
        
        if redisKeyModel.isNew || redisKeyModel.type != RedisKeyTypeEnum.ZSET.rawValue {
            return
        }
        queryPage(redisKeyModel)
    }
    
    func queryPage(_ redisKeyModel:RedisKeyModel) -> Void {
        if redisKeyModel.isNew {
            return
        }
        Task {
            let res = await redisInstanceModel.getClient().pageZSet(redisKeyModel.key, page: page)
            self.datasource = res
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
        let item = self.datasource[index]
        let text = item.value
        
        MAlert.confirm(String(format: Helps.DELETE_LIST_ITEM_CONFIRM_TITLE, text), message: String(format:Helps.DELETE_LIST_ITEM_CONFIRM_MESSAGE, text), primaryButton: "Delete", primaryAction: {
            deleteEle(index)
        })
        
    }
    
    func deleteEle(_ index:Int) -> Void {
        logger.info("delete set item, index: \(index)")
        let ele = self.datasource[index]
        Task {
            let r = await redisInstanceModel.getClient().zrem(redisKeyModel.key, ele: ele.value)
            if r > 0 {
                datasource.remove(at: index)
            }
        }
    }
}

//struct ZSetEditorView_Previews: PreviewProvider {
//    static var redisKeyModel:RedisKeyModel = RedisKeyModel(key: "tes", type: "string")
//    static var previews: some View {
//        ZSetEditorView(redisKeyModel: redisKeyModel)
//    }
//}
