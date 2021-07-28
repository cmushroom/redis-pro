//
//  ListEditorView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/30.
//

import SwiftUI
import Logging

struct SetEditorView: View {
    @State var list:[String] = [String]()
    @State private var selectIndex:Int?
    
    @EnvironmentObject var redisInstanceModel:RedisInstanceModel
    @ObservedObject var redisKeyModel:RedisKeyModel
    @StateObject private var page:ScanModel = ScanModel()
    
    @State private var editModalVisible:Bool = false
    @State private var editNewField:Bool = false
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
                SearchBar(keywords: $page.keywords, placeholder: "Search set...", action: onQueryField)
                Spacer()
                ScanBar(scanModel:page, action: onPageAction)
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
            ModalView("Edit element", action: onUpdateItemAction) {
                VStack(alignment:.leading, spacing: MTheme.V_SPACING) {
                    MTextView(text: $editValue)
                }
                .frame(minWidth:500, minHeight:300)
            }
        }
        .onChange(of: redisKeyModel, perform: { value in
            logger.info("redis set value editor view change \(value)")
            onLoad(value)
        })
        .onAppear {
            logger.info("redis set value editor view init...")
            onLoad(redisKeyModel)
        }
    }

    
    func onAddAction() throws -> Void {
        editModalVisible = true
        editNewField = true
        editIndex = -1
        editValue = ""
    }
    
    func onEditAction(_ index:Int) -> Void {
        editModalVisible = true
        editNewField = false
        editIndex = index
        editValue = list[index]
    }
    
    func onUpdateItemAction() throws -> Void {
        if editIndex == -1 {
            let _ = redisInstanceModel.getClient().sadd(redisKeyModel.key, ele: editValue).done({_ in
                try onRefreshAction()
            })
        } else {
            let _ = redisInstanceModel.getClient().supdate(redisKeyModel.key, from: list[editIndex], to: editValue ).done({ _ in
                self.logger.info("redis set update success, update list")
                self.list[editIndex] = editValue
            })
        }
        
        if self.redisKeyModel.isNew {
            redisKeyModel.isNew = false
        }
    }
    

    
    func onSubmitAction() throws -> Void {
        logger.info("redis hash value editor on submit")
        let _ = redisInstanceModel.getClient().expire(redisKeyModel.key, seconds: redisKeyModel.ttl)
    }
    
    func onRefreshAction() throws -> Void {
        page.reset()
        queryPage(redisKeyModel)
        ttl(redisKeyModel)
    }
    
    func onQueryField() throws -> Void {
        page.reset()
        queryPage(redisKeyModel)
    }
    
    func onPageAction() -> Void {
        queryPage(redisKeyModel)
    }
    
    func onLoad(_ redisKeyModel:RedisKeyModel) -> Void {
        queryPage(redisKeyModel)
    }
    
    func queryPage(_ redisKeyModel:RedisKeyModel) -> Void {
        let _ = redisInstanceModel.getClient().pageSet(redisKeyModel, page: page).done({res in
            list = res.map{ $0 ?? ""}
            self.selectIndex = res.count > 0 ? 0 : nil
        })
    }
    
    func ttl(_ redisKeyModel:RedisKeyModel) -> Void {
        let _ = redisInstanceModel.getClient().ttl(key: redisKeyModel.key).done({r in
            redisKeyModel.ttl = r
        })
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
        let _ = redisInstanceModel.getClient().srem(redisKeyModel.key, ele: ele).done({r in
            if r > 0 {
                self.list.remove(at: index)
            }
        })
    }
}

struct SetEditorView_Previews: PreviewProvider {
    static var redisKeyModel:RedisKeyModel = RedisKeyModel(key: "tes", type: "string")
    static var previews: some View {
        SetEditorView(redisKeyModel: redisKeyModel)
    }
}
