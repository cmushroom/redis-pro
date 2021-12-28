//
//  RedisConfigView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/7/21.
//

import SwiftUI
import Logging

struct RedisConfigView: View {
    let logger = Logger(label: "redis-config-view")
    
    @State private var pattern:String = ""
    @EnvironmentObject var redisInstanceModel:RedisInstanceModel
    @State private var redisConfigItemModels:[RedisConfigItemModel] = []
    @State private var selectIndex:Int?
    @State private var refresh:Int = 0
    
    @State private var editModalVisible:Bool = false
    @State private var editKey:String = ""
    @State private var editValue:String = ""
    @State private var editIndex = 0
    
    private var header: some View {
        HStack(alignment: .center , spacing: MTheme.H_SPACING) {
            SearchBar(keywords: $pattern, onCommit: {
                self.onLoad()
            }).frame(width: 500)
            Spacer()
            // TODO
            Text(editKey).hidden()
            MButton(text: "Rewrite", action: onRewriteAction)
                .help("REDIS_CONFIG_REWRITE")
        }.padding(MTheme.HEADER_PADDING)
    }
    
    private var footer: some View {
        HStack(alignment: .center , spacing: MTheme.H_SPACING) {
            Spacer()
            MButton(text: "Refresh", action: onRefrehAction)
        }
    }
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: MTheme.V_SPACING) {
            header
            
            RedisConfigTable(datasource: $redisConfigItemModels, selectRowIndex: $selectIndex, refresh: refresh, editAction: onReadyEditAction)
            
            footer
        }
        .sheet(isPresented: $editModalVisible, onDismiss: {
            logger.info("on dismiss")
        }) {
            ModalView("Edit Config Key: \(editKey)", action: onUpdateItemAction) {
                VStack(alignment:.leading, spacing: MTheme.V_SPACING) {
                    MTextView(text: $editValue)
                }
                .frame(minWidth:500, minHeight:300)
            }
        }
        .onAppear {
            onLoad()
        }
    }
    
    
    func onLoad() -> Void {
        let _ = redisInstanceModel.getClient().getConfigList(self.pattern).done({res in
            self.redisConfigItemModels = res
        })
    }
    
    func onRefrehAction() -> Void {
        self.onLoad()
    }
    
    func onRewriteAction() -> Void {
        let _ = redisInstanceModel.getClient().configRewrite()
    }
    
    func onReadyEditAction(index:Int) -> Void {
        if index < 0 {
            return
        }
        
        let editConfig = self.redisConfigItemModels[index]
        
        self.editIndex = index
        self.editKey = editConfig.key
        self.editValue = editConfig.value
        
        logger.info("......... \(editKey), \(editValue)")
        self.editModalVisible = true
    }
    
    func onUpdateItemAction() -> Void {
        let _ = redisInstanceModel.getClient().setConfig(key: editKey, value: editValue).done({res in
            self.redisConfigItemModels[editIndex].value = editValue
            self.refresh += 1
        })
    }
    
}

struct RedisConfigView_Previews: PreviewProvider {
    static var previews: some View {
        RedisConfigView()
    }
}
