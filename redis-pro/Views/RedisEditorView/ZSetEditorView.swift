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
    @StateObject private var page:ScanModel = ScanModel()
    
    @State private var editModalVisible:Bool = false
    @State private var editNewField:Bool = false
    @State private var editIndex:Int = 0
    @State private var editValue:String = ""
    @State private var editScore:String = "0"
    
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
                ScanBar(scanModel:page, action: onPageAction)
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
                                
                                Text(NumberHelper.formatDouble(list[index]?.1))
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
                                    editScore = NumberHelper.formatDouble(list[index]?.1)
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
//                IconButton(icon: "checkmark", name: "Submit", confirmPrimaryButtonText: "Submit", action: onSubmitAction)
            }
            .padding(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
        }
        .sheet(isPresented: $editModalVisible, onDismiss: {
            print("on dismiss")
        }) {
            ModalView("Edit element", action: onUpdateItemAction) {
                VStack(alignment:.leading, spacing: 8) {
//                    TextField("", value: $editScore, formatter: NumberFormatter())
                    FormItemNumber(label: "Score", placeholder: "score", value: $editScore)
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
        let item = list[index] ?? ("", 0)
        
        globalContext.confirm(String(format: Helps.DELETE_LIST_ITEM_CONFIRM_TITLE, item.0)
                              , alertMessage: String(format:Helps.DELETE_LIST_ITEM_CONFIRM_MESSAGE, item.0)
                              , primaryAction: {
                                try deleteEle(index)
                              }
                              , primaryButton: "Delete")
        
    }
    
    func onAddAction() throws -> Void {
        editModalVisible = true
        editNewField = true
        editIndex = -1
        editValue = ""
        editScore = "0"
    }
    
    func onUpdateItemAction() throws -> Void {
        let score:Double = Double(editScore) ?? 0
        if editIndex == -1 {
            let _ = redisInstanceModel.getClient().zadd(redisKeyModel.key, score: score, ele: editValue).done({ _ in
                try onRefreshAction()
            })
        } else {
            let editEle = list[editIndex] ?? ("", 0)
            let _ = try redisInstanceModel.getClient().zupdate(redisKeyModel.key, from: editEle.0, to: editValue, score: score ).done({_ in
                self.logger.info("redis zset update success, update list")
                self.list[editIndex] = (editValue, score)
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
        try ttl(redisKeyModel)
    }
    
    func onQueryField() -> Void {
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
        let _ = redisInstanceModel.getClient().pageZSet(redisKeyModel, page: page).done({ res in
            self.list = res
        })
    }
    
    func ttl(_ redisKeyModel:RedisKeyModel) throws -> Void {
        let _ = redisInstanceModel.getClient().ttl(key: redisKeyModel.key).done({r in
            redisKeyModel.ttl = r
        })
    }
    
    func deleteEle(_ index:Int) throws -> Void {
        logger.info("delete set item, index: \(index)")
        let ele = list[index]
        if ele == nil {
            list.remove(at: index)
            return
        }
        
        let _ = redisInstanceModel.getClient().zrem(redisKeyModel.key, ele: ele!.0).done({ r in
            if r > 0 {
                list.remove(at: index)
            }
        })
    }
}

struct ZSetEditorView_Previews: PreviewProvider {
    static var redisKeyModel:RedisKeyModel = RedisKeyModel(key: "tes", type: "string")
    static var previews: some View {
        ZSetEditorView(redisKeyModel: redisKeyModel)
    }
}
