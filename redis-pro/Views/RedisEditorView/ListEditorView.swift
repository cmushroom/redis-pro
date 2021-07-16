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
    
    @State private var datasource:[Any] = ["1", "2"]
    
    var delButtonDisabled:Bool {
        selectIndex == nil
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
            
//            List(selection: $selectIndex) {
//                ForEach(0..<list.count, id: \.self) { index in
//                    HStack {
//                        Text(list[index] ?? "")
//                            .font(.body)
//                            .multilineTextAlignment(.leading)
//                            .frame(alignment: .leading)
//                        Spacer()
//                    }
//                    .contextMenu {
//                        Button(action: {
//                            editModalVisible = true
//                            editNewField = false
//                            editIndex = index
//                            editValue = list[index] ?? ""
//                        }){
//                            Text("Edit")
//                        }
//                        Button(action: {
//                            onDeleteConfirmAction(index)
//                        }){
//                            Text("Delete")
//                        }
//                    }
//                    .padding(EdgeInsets(top: 4, leading: 2, bottom: 4, trailing: 2))
//                    .overlay(
//                        Rectangle()
//                            .frame(height: 1)
//                            .foregroundColor(Color.gray.opacity(0.1)),
//                        alignment: .bottom
//                    )
//                    .listRowInsets(EdgeInsets())
//                }
//
//            }
//            .listStyle(PlainListStyle())
//            .padding(.all, 0)
            
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
            ModalView("Edit item", action: onUpdateItemAction) {
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
    
    func onEditAction(_ index:Int) -> Void {
        editNewField = false
        editIndex = index
        editValue = list[index] ?? ""
        
        editModalVisible = true
    }
    
    func onDeleteConfirmAction(_ index:Int) -> Void {
        let item = list[index] ?? "''"
        
        globalContext.confirm(String(format: Helps.DELETE_LIST_ITEM_CONFIRM_TITLE, item), alertMessage: String(format:Helps.DELETE_LIST_ITEM_CONFIRM_MESSAGE, item)
                              , primaryAction: {
                                try deleteField(index)
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
        if editIndex == -1 {
            let _ = redisInstanceModel.getClient().lpush(redisKeyModel.key, value: editValue).done({ _ in
                try onRefreshAction()
            })
        } else if editIndex == -2 {
            let _ = redisInstanceModel.getClient().rpush(redisKeyModel.key, value: editValue).done({_ in
                try onRefreshAction()
            })
        } else {
            let index = (page.current - 1) * page.size + editIndex
            let _ = redisInstanceModel.getClient().lset(redisKeyModel.key, index: index, value: editValue).done({ _ in
                logger.info("redis list set success, update list")
                list[editIndex] = editValue
            })
        }
        
        if redisKeyModel.isNew {
            self.redisKeyModel.isNew = false
        }
    }
    
    func onDeleteAction() throws -> Void {
        try deleteField(selectIndex!)
        try onRefreshAction()
    }
    
    func onSubmitAction() throws -> Void {
        logger.info("redis hash value editor on submit")
        let _ = redisInstanceModel.getClient().expire(redisKeyModel.key, seconds: redisKeyModel.ttl)
    }
    
    func onRefreshAction() throws -> Void {
        page.firstPage()
        try queryPage(redisKeyModel)
        try ttl(redisKeyModel)
    }
    
    
    func onPageAction() throws -> Void {
        try queryPage(redisKeyModel)
    }
    
    func onLoad(_ redisKeyModel:RedisKeyModel) -> Void {
        do {
            try queryPage(redisKeyModel)
        } catch {
            logger.error("on string editor view load query redis hash error:\(error)")
            globalContext.showError(error)
        }
    }
    
    func queryPage(_ redisKeyModel:RedisKeyModel) throws -> Void {
        
        let _ = redisInstanceModel.getClient().pageList(redisKeyModel, page: page).done({res in
            self.list = res.map{ $0 ?? ""}
        })
        
    }
    
    func ttl(_ redisKeyModel:RedisKeyModel) throws -> Void {
        let _  = redisInstanceModel.getClient().ttl(key: redisKeyModel.key).done({r in
            redisKeyModel.ttl = r
        })
    }
    
    func deleteField(_ index:Int) throws -> Void {
        logger.info("delete list item, index: \(index)")
        let _ = redisInstanceModel.getClient().ldel(redisKeyModel.key, index: index).done({r in
            if r > 0 {
                self.list.remove(at: index)
            }
        })
    }
}

struct ListEditorView_Previews: PreviewProvider {
    static var redisKeyModel:RedisKeyModel = RedisKeyModel(key: "tes", type: "string")
    static var previews: some View {
        ListEditorView(redisKeyModel: redisKeyModel)
    }
}
