//
//  ListEditorView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/30.
//

import SwiftUI
import Logging
import ComposableArchitecture

struct SetEditorView: View {
    
    var store:Store<SetValueState, SetValueAction>
    let logger = Logger(label: "redis-set-editor")
    
    var body: some View {
        WithViewStore(store) { viewStore in
            
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center , spacing: 4) {
                IconButton(icon: "plus", name: "Add", action: {viewStore.send(.addNew)})
                IconButton(icon: "trash", name: "Delete", disabled: viewStore.tableState.selectIndex < 0, action: {viewStore.send(.deleteConfirm(viewStore.tableState.selectIndex))})

                Spacer()
                PageBar(showTotal: true, store: store.scope(state: \.pageState, action: SetValueAction.pageAction))
            }
            .padding(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
            
            NTableView(store: store.scope(state: \.tableState, action: SetValueAction.tableAction))

            
            // footer
            HStack(alignment: .center, spacing: MTheme.H_SPACING) {
                Spacer()
                IconButton(icon: "arrow.clockwise", name: "Refresh", action: {viewStore.send(.refresh)})
            }
            .padding(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
        }
        .sheet(isPresented: viewStore.binding(\.$editModalVisible), onDismiss: {
        }) {
            ModalView("Edit set element", action: {viewStore.send(.submit)}) {
                VStack(alignment:.leading, spacing: MTheme.V_SPACING) {
                    FormItemTextArea(label: "Value", placeholder: "value", value: viewStore.binding(\.$editValue))
                }
            }
        }
        }
    }
//    
//    func onUpdateItemAction() throws -> Void {
//        Task {
//            if editIndex == -1 {
//                let r = await redisInstanceModel.getClient().sadd(redisKeyModel.key, ele: editValue)
//                if r > 0 {
//                    self.onSubmit?()
//                    try onRefreshAction()
//                }
//                
//            } else {
//                let fromValue = self.list[self.editIndex]
//                let r = await redisInstanceModel.getClient().supdate(redisKeyModel.key, from: fromValue, to: editValue )
//                if r > 0 {
//                    self.logger.info("redis set update success, update list")
//                    self.list[editIndex] = editValue
//                }
//            }
//        }
//    }
//    
//
//    
//    func onSubmitAction() throws -> Void {
//        logger.info("redis hash value editor on submit")
//        Task {
//            let _ = await redisInstanceModel.getClient().expire(redisKeyModel.key, seconds: redisKeyModel.ttl)
//        }
//    }
//    
//    func onRefreshAction() throws -> Void {
//        page.reset()
//        queryPage(redisKeyModel)
//        Task {
//            await ttl(redisKeyModel)
//        }
//    }
//    
//    func onQueryField() -> Void {
//        page.reset()
//        queryPage(redisKeyModel)
//    }
//    
//    func onPageAction() -> Void {
//        queryPage(redisKeyModel)
//    }
//    
//    func onLoad() -> Void {
//        
//        if  redisKeyModel.type != RedisKeyTypeEnum.SET.rawValue {
//            return
//        }
//    
//        page.reset()
//        queryPage(redisKeyModel)
//    }
//    
//    func queryPage(_ redisKeyModel:RedisKeyModel) -> Void {
//        
//        if redisKeyModel.isNew {
//            return
//        }
//        
//        Task {
//            let res = await redisInstanceModel.getClient().pageSet(redisKeyModel.key, page: page)
//            list = res.map{ $0 ?? ""}
//            self.selectIndex = res.count > 0 ? 0 : nil
//        }
//    }
//    
//    func ttl(_ redisKeyModel:RedisKeyModel) async -> Void {
//        let r = await redisInstanceModel.getClient().ttl(redisKeyModel.key)
//        self.redisKeyModel.ttl = r
//    }
//    
//    
//    // delete
//    func onDeleteAction() throws -> Void {
//        onDeleteConfirmAction(selectIndex!)
//    }
//    
//    func onDeleteConfirmAction(_ index:Int) -> Void {
//        let item = list[index]
//        
////        MAlert.confirm(String(format: Helps.DELETE_LIST_ITEM_CONFIRM_TITLE, item), message: String(format:Helps.DELETE_LIST_ITEM_CONFIRM_MESSAGE, item), primaryButton: "Delete", primaryAction: {
////            deleteEle(index)
////        })
//    }
//    
//    func deleteEle(_ index:Int) -> Void {
//        logger.info("delete set item, index: \(index)")
//        let ele = list[index]
//        Task {
//        let r = await redisInstanceModel.getClient().srem(redisKeyModel.key, ele: ele)
//        if r > 0 {
//            self.list.remove(at: index)
//        }
//        }
//    }
}

//struct SetEditorView_Previews: PreviewProvider {
//    static var redisKeyModel:RedisKeyModel = RedisKeyModel(key: "tes", type: "string")
//    static var previews: some View {
//        SetEditorView(redisKeyModel: redisKeyModel)
//    }
//}
