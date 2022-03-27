//
//  RedisInstanceList.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/1/25.
//

import SwiftUI
import Logging

func onAppear() {
    print("list on appear。。。")
}

struct RedisListView: View {
    let logger = Logger(label: "redis-login")
    
    @EnvironmentObject var redisInstanceModel:RedisInstanceModel
    @EnvironmentObject var globalContext:GlobalContext
    @StateObject var redisFavoriteModel: RedisFavoriteModel = RedisFavoriteModel()
    @State private var showFavoritesOnly = false
    @State private var selectedRedisModelId: String?
    @State private var selectIndex:Int?
    
    @State private var selectRedisModel = RedisModel()
    
//    @StateObject private var selectRedisModel = RedisModel()
    
    @AppStorage("User.defaultFavorite")
    private var defaultFavorite:String = "last"
    
    var quickRedisModel:[RedisModel] = [RedisModel](repeating: RedisModel(name: "QUICK CONNECT"), count: 1)
    
//    var selectRedisModel: RedisModel {
//        return redisFavoriteModel.redisModels[selectIndex ?? 0]
//    }

    var filteredRedisModel: [RedisModel] {
        redisFavoriteModel.redisModels
    }
    
    var redisTable:some View {
        RedisListTable(datasource: $redisFavoriteModel.redisModels, selectRowIndex: $selectIndex, onChange: {
            logger.info("on table select change \($0)")
            self.selectRedisModel = redisFavoriteModel.redisModels[$0]
            self.selectedRedisModelId = redisFavoriteModel.redisModels[$0].id
        }, doubleAction: self.onConnect)
    }
    
    var body: some View {
        HSplitView {
            VStack(alignment: .leading,
                   spacing: 0) {
                redisTable

                // footer
                HStack(alignment: .center) {
                    MIcon(icon: "plus", fontSize: 13, action: onAddAction)
                    MIcon(icon: "minus", fontSize: 13, disabled: selectedRedisModelId == nil, action: onConfirmDel)
                    
                }
                .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
            }
            .padding(0)
            .frame(minWidth:200)
            .layoutPriority(0)
            .onAppear{
                logger.info("load all redis favorite list")
                redisFavoriteModel.loadAll()
                selectFavoriteRedisModel()
            }
            
            LoginForm(redisFavoriteModel: redisFavoriteModel, redisModel: $selectRedisModel)
            .frame(minWidth: 500, idealWidth:500, maxWidth: .infinity, minHeight: 400, idealHeight: 400, maxHeight: .infinity)
        }
    }
    
    func selectFavoriteRedisModel() -> Void {
        if defaultFavorite == "last" {
            self.selectedRedisModelId = self.redisFavoriteModel.lastRedisModelId
        } else {
            self.selectedRedisModelId = defaultFavorite
        }
        
        if let index = self.redisFavoriteModel.redisModels.firstIndex(where: { (e) -> Bool in
            return e.id == self.selectedRedisModelId
        }) {
            self.selectIndex = index
        }
        self.selectRedisModel = self.redisFavoriteModel.redisModels[self.selectIndex ?? 0]
    }
    
    func onAddAction() -> Void {
        logger.info("add new redis favorite action")
        redisFavoriteModel.save(redisModel: RedisModel())
    }
    
    func onConfirmDel() -> Void {
        if let index = self.redisFavoriteModel.redisModels.firstIndex(where: { (e) -> Bool in
            return e.id == self.selectedRedisModelId
        }) {
            self.selectIndex = index
        }
        self.selectRedisModel = self.redisFavoriteModel.redisModels[self.selectIndex ?? 0]
        
        MAlert.confirm(String(format: NSLocalizedString("CONFIRM_FAVORITE_REDIS_TITLE'%@'", comment: ""), self.selectRedisModel.name)
                       , message: String(format: NSLocalizedString("CONFIRM_FAVORITE_REDIS_MESSAGE'%@'", comment: ""), self.selectRedisModel.name)
                       , primaryButton: "Delete"
                       , primaryAction: {
                        onDelAction()
                       })
    }
    
    func onDelAction() -> Void {
        logger.info("del redis favorite action, id:\(String(describing: selectedRedisModelId))")
        if selectedRedisModelId == nil {
            return
        }
        
        let nextId:String? = redisFavoriteModel.delete(id: selectedRedisModelId!)
        selectedRedisModelId = nextId
    }
    
    func onConnect() -> Void {
        Task {
            let r = await redisInstanceModel.connect(redisModel:selectRedisModel)
            redisFavoriteModel.saveLast(redisModel: selectRedisModel)
            logger.info("on connect to redis server result: \(r), redis: \(selectRedisModel)")
        }
    }
}


struct RedisInstanceList_Previews: PreviewProvider {
    private static var redisFavoriteModel: RedisFavoriteModel = RedisFavoriteModel()
    static var previews: some View {
        RedisListView()
            .environmentObject(redisFavoriteModel)
            .onAppear{
                redisFavoriteModel.loadAll()
            }
        
    }
}
