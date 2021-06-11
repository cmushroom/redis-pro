//
//  ListEditorView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/30.
//

import SwiftUI
import Logging

struct SetEditorView: View {
    @State var text:String = ""
    @State var list:[String?] = [String?]()
    @State private var selectIndex:Int?
    @State private var isEditing:Bool = false
    @EnvironmentObject var redisInstanceModel:RedisInstanceModel
    @EnvironmentObject var globalContext:GlobalContext
    @ObservedObject var redisKeyModel:RedisKeyModel
    @StateObject private var page:ScanModel = ScanModel()
    
    @State private var editModalVisible:Bool = false
    @State private var editNewField:Bool = false
    @State private var editIndex:Int = 0
    @State private var editValue:String = ""
    
    
    var delButtonDisabled:Bool {
        selectIndex == nil
    }
    var selectItem:String? {
        selectIndex == nil || selectIndex! >= list.count ? nil : list[selectIndex!]
    }
    
    let logger = Logger(label: "redis-set-editor")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center , spacing: 4) {
                IconButton(icon: "plus", name: "Add", action: onAddAction)
                IconButton(icon: "trash", name: "Delete", disabled:delButtonDisabled,
                           isConfirm: true,
                           confirmTitle: String(format: Helps.DELETE_LIST_ITEM_CONFIRM_TITLE, selectItem ?? ""),
                           confirmMessage: String(format:Helps.DELETE_LIST_ITEM_CONFIRM_MESSAGE, selectItem ?? ""),
                           confirmPrimaryButtonText: "Delete",
                           action: onDeleteAction)
                SearchBar(keywords: $page.keywords, placeholder: "Search set...", action: onQueryField)
                Spacer()
                ScanBar(scanModel:page, action: onPageAction)
            }
            .padding(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
            
            List(selection: $selectIndex) {
                ForEach(0..<list.count, id: \.self) { index in
                    HStack {
                        Text(list[index] ?? "")
                            .font(.body)
                            .multilineTextAlignment(.leading)
                            .frame(alignment: .leading)
                        Spacer()
                    }
                    .contextMenu {
                        Button(action: {
                            editModalVisible = true
                            editNewField = false
                            editIndex = index
                            editValue = list[index] ?? ""
                        }){
                            Text("Edit")
                        }
                        Button(action: {
                            onDeleteConfirmAction(index)
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
//                IconButton(icon: "checkmark", name: "Submit", confirmPrimaryButtonText: "Submit", action: onSubmitAction)
            }
            .padding(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
        }
        .sheet(isPresented: $editModalVisible, onDismiss: {
            print("on dismiss")
        }) {
            ModalView("Edit element", action: onUpdateItemAction) {
                VStack(alignment:.leading, spacing: 8) {
                    FormItemTextArea(label: "", placeholder: "value", value: $editValue)
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
    
    
    func onDeleteConfirmAction(_ index:Int) -> Void {
        globalContext.alertVisible = true
        globalContext.showSecondButton = true
        globalContext.primaryButtonText = "Delete"
        
        let item = list[index] ?? "''"
        globalContext.alertTitle = String(format: Helps.DELETE_LIST_ITEM_CONFIRM_TITLE, item)
        globalContext.alertMessage = String(format:Helps.DELETE_LIST_ITEM_CONFIRM_MESSAGE, item)
        globalContext.primaryAction = {
            try deleteEle(index)
        }
        
    }
    
    func onAddAction() throws -> Void {
        editModalVisible = true
        editNewField = true
        editIndex = -1
        editValue = ""
    }
    
    func onUpdateItemAction() throws -> Void {
        if editIndex == -1 {
            let _ = redisInstanceModel.getClient().sadd(redisKeyModel.key, ele: editValue).done({_ in
                try onRefreshAction()
            })
        } else {
            let _ = redisInstanceModel.getClient().supdate(redisKeyModel.key, from: list[editIndex] ?? "", to: editValue ).done({ _ in
                self.logger.info("redis set update success, update list")
                self.list[editIndex] = editValue
            })
        }
        
        if self.redisKeyModel.isNew {
            redisKeyModel.isNew = false
        }
    }
    
    func onDeleteAction() throws -> Void {
        try deleteEle(selectIndex!)
        try onRefreshAction()
    }
    
    func onSubmitAction() throws -> Void {
        logger.info("redis hash value editor on submit")
        let _ = redisInstanceModel.getClient().expire(redisKeyModel.key, seconds: redisKeyModel.ttl)
    }
    
    func onRefreshAction() throws -> Void {
        page.resetHead()
        queryPage(redisKeyModel)
        ttl(redisKeyModel)
    }
    
    func onQueryField() throws -> Void {
        page.resetHead()
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
            list = res
        })
    }
    
    func ttl(_ redisKeyModel:RedisKeyModel) -> Void {
        let _ = redisInstanceModel.getClient().ttl(key: redisKeyModel.key).done({r in
            redisKeyModel.ttl = r
        })
    }
    
    func deleteEle(_ index:Int) throws -> Void {
        logger.info("delete set item, index: \(index)")
        let ele = list[index] ?? ""
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
