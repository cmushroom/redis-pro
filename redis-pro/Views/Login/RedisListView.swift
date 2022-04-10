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
    @State private var selectIndex:Int = -1
    @State private var datasource:[Any] = [RedisModel()]
    
    @State private var selectRedisModel = RedisModel()
    
    @AppStorage("User.defaultFavorite")
    private var defaultFavorite:String = "last"
    
    var quickRedisModel:[RedisModel] = [RedisModel](repeating: RedisModel(name: "QUICK CONNECT"), count: 1)
    
    var redisTable:some View {
//        RedisListTable(datasource: $redisFavoriteModel.redisModels, selectRowIndex: $selectIndex, onChange: {
//            logger.info("on table select change \($0)")
//            self.selectRedisModel = redisFavoriteModel.redisModels[$0]
//            self.selectedRedisModelId = redisFavoriteModel.redisModels[$0].id
//        }, doubleAction: self.onConnect)
        NTableView(columns: [NTableColumn(title: "FAVORITES", key: "name", width: 50, icon: .APP)], datasource: $datasource, selectIndex: $selectIndex, onChange: {
            self.selectRedisModel = self.datasource[$0] as! RedisModel
        }, onDelete: {
            self.selectIndex = $0
            self.onConfirmDel()
        }, onDouble: {
            self.selectIndex = $0
            self.onConnect()
        })
    }
    
    var body: some View {
        HSplitView {
            VStack(alignment: .leading,
                   spacing: 0) {
                redisTable

                // footer
                HStack(alignment: .center) {
                    MIcon(icon: "plus", fontSize: 13, action: onAddAction)
                    MIcon(icon: "minus", fontSize: 13, disabled: selectIndex < 0, action: onConfirmDel)
                    
                }
                .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
            }
            .padding(0)
            .frame(minWidth:200)
            .layoutPriority(0)
            .onAppear{
                logger.info("load all redis favorite list")
                redisFavoriteModel.loadAll()
                onLoad()
            }
            
            LoginForm(redisFavoriteModel: redisFavoriteModel, redisModel: $selectRedisModel)
            .frame(minWidth: 500, idealWidth:500, maxWidth: .infinity, minHeight: 400, idealHeight: 400, maxHeight: .infinity)
        }
    }
    
    func onLoad() {
        self.datasource = RedisDefaults.getAll()
        initDefaultSelection()
    }
    
    func initDefaultSelection() -> Void {
        let index = getDefaultSelection()
        logger.info("init default selection, index: \(index)")
        if (index == -1) {
            return
        }
        
        self.selectIndex = index
        self.selectRedisModel = self.datasource[index] as! RedisModel
    }
    
    func getDefaultSelection() -> Int {
        var selectId:String?
        if defaultFavorite == "last" {
            selectId = RedisDefaults.getLastId()
        } else {
            selectId = defaultFavorite
        }
        
        guard let selectId = selectId else {
            return self.datasource.count > 0 ? 0 : -1
        }
        
        if let index = self.datasource.firstIndex(where: { (e) -> Bool in
            return (e as! RedisModel).id == selectId
        }) {
            return index
        }
        
        return self.datasource.count > 0 ? 0 : -1
    }
    
    func onAddAction() -> Void {
        logger.info("on add new redis model action")
        let new = RedisModel()
        RedisDefaults.save(new)
        datasource.append(new)
//        redisFavoriteModel.save(redisModel: RedisModel())
        
    }
    
    func onConfirmDel() -> Void {
        if self.selectIndex < 0 {
            return
        }
        
        let deleteRedis = datasource[self.selectIndex] as! RedisModel
        
        self.selectRedisModel = self.redisFavoriteModel.redisModels[self.selectIndex]
        
        MAlert.confirm(String(format: NSLocalizedString("CONFIRM_FAVORITE_REDIS_TITLE'%@'", comment: ""), deleteRedis.name)
                       , message: String(format: NSLocalizedString("CONFIRM_FAVORITE_REDIS_MESSAGE'%@'", comment: ""), deleteRedis.name)
                       , primaryButton: "Delete"
                       , primaryAction: {
                            self.deleteRedis()
                       })
    }
    
    func deleteRedis() -> Void {
        logger.info("del redis favorite action, id:\(String(describing: selectIndex))")
        if selectIndex < 0 {
            return
        }
        
        if RedisDefaults.delete(selectIndex) {
            datasource.remove(at: selectIndex)
        }
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
