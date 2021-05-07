//
//  ZSetEditorView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/5/7.
//

import SwiftUI
import Logging

struct ZSetEditorView: View {
    @State var text:String = ""
    @State var list:[(String, Double)?] = [(String, Double)?]()
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
    @State private var editScore:Double = 0
    
    
    var delButtonDisabled:Bool {
        selectIndex == nil
    }
    var selectEle:(String, Double)? {
        selectIndex == nil || selectIndex! >= list.count ? nil : list[selectIndex!]
    }
    var selectEleValue:String {
        selectEle == nil ? "" : selectEle!.0
    }
    
    let logger = Logger(label: "redis-set-editor")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center , spacing: 4) {
                IconButton(icon: "plus", name: "Add", action: onAddAction)
                IconButton(icon: "trash", name: "Delete", disabled:delButtonDisabled,
                           isConfirm: true,
                           confirmTitle: String(format: Helps.DELETE_LIST_ITEM_CONFIRM_TITLE, "selectEleValue"),
                           confirmMessage: String(format:Helps.DELETE_LIST_ITEM_CONFIRM_MESSAGE, "selectEleValue"),
                           confirmPrimaryButtonText: "Delete",
                           action: onDeleteAction)
                SearchBar(keywords: $page.keywords, placeholder: "Search set...", action: onQueryField)
                Spacer()
                PageBar(page:page, action: onPageAction)
            }
            .padding(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
            
            GeometryReader { geometry in
                let width0 = geometry.size.width/2
                let width1 = width0
                List(selection: $selectIndex) {
                    Section(header: HStack {
                        Text("Value")
                            .frame(width: width0, alignment: .leading)
                        Text("Score")
                            .frame(width: width1, alignment: .leading)
                            .padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 0))
                            .border(width:1, edges: [.leading], color: Color.gray)
                    }) {
                        ForEach(0..<list.count, id: \.self) { index in
                            HStack {
                                Text(list[index]?.0 ?? "")
                                    .font(.body)
                                    .multilineTextAlignment(.leading)
                                    .frame(width: width0, alignment: .leading)
                                
                                Text(list[index]?.1.description ?? "0")
                                    .font(.body)
                                    .multilineTextAlignment(.leading)
                                    .frame(width: width1, alignment: .leading)
                            }
                            .contextMenu {
                                Button(action: {
                                    editModalVisible = true
                                    editNewField = false
                                    editIndex = index
                                    editValue = list[index]?.0 ?? ""
                                    editScore = list[index]?.1 ?? 0
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
                }
                .listStyle(PlainListStyle())
                .padding(.all, 0)
            }
            
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
            ModalView("Edit element", action: onUpdateItemAction) {
                VStack(alignment:.leading, spacing: 8) {
                    FormItemDouble(label: "Score", placeholder: "score", value: $editScore)
                    FormItemTextArea(label: "Value", placeholder: "value", value: $editValue)
                }
                .frame(minWidth:500, minHeight:300)
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
    
    func onDeleteConfirmAction(_ index:Int) -> Void {
        globalContext.alertVisible = true
        globalContext.showSecondButton = true
        globalContext.primaryButtonText = "Delete"
        
        let item = list[index] ?? ("", 0)
        globalContext.alertTitle = String(format: Helps.DELETE_LIST_ITEM_CONFIRM_TITLE, item.0)
        globalContext.alertMessage = String(format:Helps.DELETE_LIST_ITEM_CONFIRM_MESSAGE, item.0)
        globalContext.primaryAction = {
            try deleteEle(index)
        }
        
    }
    
    func onAddAction() throws -> Void {
        editModalVisible = true
        editNewField = true
        editIndex = -1
        editValue = ""
        editScore = 0
    }
    
    func onUpdateItemAction() throws -> Void {
        if editIndex == -1 {
            let _ = try redisInstanceModel.getClient().zadd(redisKeyModel.key, score: editScore, ele: editValue)
            try onRefreshAction()
        } else {
            let editEle = list[editIndex] ?? ("", 0)
            let _ = try redisInstanceModel.getClient().zupdate(redisKeyModel.key, from: editEle.0, to: editValue, score: editScore )
            logger.info("redis zset update success, update list")
            list[editIndex] = (editValue, editScore)
        }
    }
    
    func onDeleteAction() throws -> Void {
        try deleteEle(selectIndex!)
        try onRefreshAction()
    }
    
    func onSubmitAction() throws -> Void {
        logger.info("redis hash value editor on submit")
        let _ = try redisInstanceModel.getClient().expire(redisKeyModel.key, seconds: redisKeyModel.ttl)
    }
    
    func onRefreshAction() throws -> Void {
        page.firstPage()
        try queryPage(redisKeyModel)
        try ttl(redisKeyModel)
    }
    
    func onQueryField() throws -> Void {
        try queryPage(redisKeyModel)
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
        list = try redisInstanceModel.getClient().pageZSet(redisKeyModel.key, page: page)
    }
    
    func ttl(_ redisKeyModel:RedisKeyModel) throws -> Void {
        redisKeyModel.ttl = try redisInstanceModel.getClient().ttl(key: redisKeyModel.key)
    }
    
    func deleteEle(_ index:Int) throws -> Void {
        logger.info("delete set item, index: \(index)")
        let ele = list[index]
        if ele == nil {
            list.remove(at: index)
            return
        }
        
        let r = try redisInstanceModel.getClient().zrem(redisKeyModel.key, ele: ele!.0)
        if r > 0 {
            list.remove(at: index)
        }
    }
}

struct ZSetEditorView_Previews: PreviewProvider {
    static var redisKeyModel:RedisKeyModel = RedisKeyModel(key: "tes", type: "string")
    static var previews: some View {
        ZSetEditorView(redisKeyModel: redisKeyModel)
    }
}
