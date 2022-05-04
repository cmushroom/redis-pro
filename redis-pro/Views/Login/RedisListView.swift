//
//  RedisInstanceList.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/1/25.
//

import SwiftUI
import Logging
import ComposableArchitecture

struct RedisListView: View {
    let logger = Logger(label: "redis-login")
    
    @EnvironmentObject var redisInstanceModel:RedisInstanceModel
    @EnvironmentObject var globalContext:GlobalContext
    @StateObject var redisFavoriteModel: RedisFavoriteModel = RedisFavoriteModel()
    // 一定要设置-1, 其它值会在view 刷新时， 陷入无限循环
    @State private var selectIndex:Int = -1
    @State private var datasource:[AnyHashable] = []
    @State private var selectRedisModel = RedisModel()
    
    @AppStorage("User.defaultFavorite")
    private var defaultFavorite:String = "last"
//
//    let store:Store<TableState, TableAction> = Store(initialState: TableState(columns: [NTableColumn(title: "FAVORITES", key: "name", width: 50, icon: .APP)], datasource: [RedisModel(name: UUID().uuidString)], selectIndex: -1)
//                      , reducer: tableReducer, environment: TableEnvironment())
//    var store:Store<FavoriteState, FavoriteAction> = Store(initialState: FavoriteState(), reducer: favoriteReducer, environment: FavoriteEnvironment())
    var store:Store<FavoriteState, FavoriteAction>
    
    var redisTable:some View {
//        RedisListTable(datasource: $redisFavoriteModel.redisModels, selectRowIndex: $selectIndex, onChange: {
//            logger.info("on table select change \($0)")
//            self.selectRedisModel = redisFavoriteModel.redisModels[$0]
//            self.selectedRedisModelId = redisFavoriteModel.redisModels[$0].id
//        }, doubleAction: self.onConnect)
            NTableView(
//                columns: [NTableColumn(title: "FAVORITES", key: "name", width: 50, icon: .APP)], datasource: $datasource, selectIndex: $selectIndex
//                       , onChange: {
//                print("on change \($0) , \(self.datasource.count)")
                //            self.selectIndex = $0
//                self.selectRedisModel = $1 as! RedisModel
//            }
//                       , onDelete: { index, _ in
//                self.onConfirmDel(index)
//            }
//                       , onDouble: {
//                //            self.selectIndex = $0
//                self.selectRedisModel = $1 as! RedisModel
//                self.onConnect()
//            },
                store: store.scope(state: \.tableState, action: FavoriteAction.tableAction)
            )
        
    }
    
    var body: some View {
        WithViewStore(store) { viewStore in
            HSplitView {
                VStack(alignment: .leading,
                       spacing: 0) {
                    redisTable
                    
                    // footer
                    HStack(alignment: .center) {
                        MIcon(icon: "plus", fontSize: 13, action: onAddAction)
                        MIcon(icon: "minus", fontSize: 13, disabled: selectIndex < 0, action: {
                            self.onConfirmDel(selectIndex)
                        })
                    }
                    .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                    
                    
                    HStack {
                        Button("select", action: {
                            viewStore.send(.tableAction(.onSelectionChange(0)))
                        })
                        
                        Button("double", action: {
                            viewStore.send(.tableAction(.onDouble(0)))
                        })
                    }
                }
                       .padding(0)
                       .frame(minWidth:200)
                       .layoutPriority(0)
                       .onAppear{
//                           logger.info("load all redis favorite list")
                           //                redisFavoriteModel.loadAll()
                           onLoad(viewStore)
                       }
                LoginForm(redisFavoriteModel: redisFavoriteModel, redisModel: $selectRedisModel, store: store.scope(state: \.loginState, action: FavoriteAction.loginAction))
                    .frame(minWidth: 500, idealWidth:500, maxWidth: .infinity, minHeight: 400, idealHeight: 400, maxHeight: .infinity)
            }
        }
    }
    
    func onLoad(_ viewStore:ViewStore<FavoriteState, FavoriteAction>) {
//        self.datasource = RedisDefaults.getAll()
//        self.datasource.removeAll()
//        self.datasource.append(contentsOf: RedisDefaults.getAll())
//        initDefaultSelection()
        viewStore.send(.getAll)
        viewStore.send(.initDefaultSelection)
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
    
    func onConfirmDel(_ index:Int) -> Void {
        if self.selectIndex < 0 {
            return
        }
        
        let deleteRedis = self.datasource[index] as! RedisModel
        logger.info("confirm delete redis, name: \(deleteRedis.name), index: \(self.selectIndex)")

        MAlert.confirm(String(format: NSLocalizedString("CONFIRM_FAVORITE_REDIS_TITLE'%@'", comment: ""), deleteRedis.name)
                       , message: String(format: NSLocalizedString("CONFIRM_FAVORITE_REDIS_MESSAGE'%@'", comment: ""), deleteRedis.name)
                       , primaryButton: "Delete"
                       , primaryAction: {
            self.deleteRedis(index)
        }
        )
    }
    
    func deleteRedis(_ index:Int) -> Void {
        logger.info("delete redis favorite, index:\(index)")
        
        if RedisDefaults.delete(selectIndex) {
            datasource.remove(at: selectIndex)
        }
    }
    
    func onConnect() -> Void {
        Task {
            let r = await redisInstanceModel.connect(redisModel:selectRedisModel)
//            redisFavoriteModel.saveLast(redisModel: selectRedisModel)
            RedisDefaults.saveLastUse(selectRedisModel)
            logger.info("on connect to redis server result: \(r), redis: \(selectRedisModel)")
        }
    }
}


//struct RedisInstanceList_Previews: PreviewProvider {
//    private static var redisFavoriteModel: RedisFavoriteModel = RedisFavoriteModel()
//    static var previews: some View {
//        RedisListView()
//            .environmentObject(redisFavoriteModel)
//            .onAppear{
//                redisFavoriteModel.loadAll()
//            }
//
//    }
//}
