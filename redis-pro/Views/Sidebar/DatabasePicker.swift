//
//  DatabasePicker.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/5/10.
//

import SwiftUI
import ComposableArchitecture

struct DatabasePicker: View {
//    @EnvironmentObject var redisInstanceModel:RedisInstanceModel
//    @State private var databases:Int = 16
//    @State var database:Int = 0
//    @State var selection = 0
//    var onChange: (() -> Void)?
//
    var store:Store<DatabaseState, DatabaseAction>
    
    var body: some View {
        WithViewStore(store) {viewStore in
            
            Menu(content: {
                ForEach(0 ..< viewStore.databases, id: \.self) { item in
                    Button("DB\(item)", action: { viewStore.send(.change(item))})
                        .font(.system(size: 10.0))
                        .foregroundColor(.primary)
                }
            }, label: {
                MLabel(name: "DB\(viewStore.database)", icon: "cylinder.split.1x2").font(.system(size: 8))
            })
            .scaleEffect(0.9)
            .frame(width:56)
            .menuStyle(BorderlessButtonMenuStyle())
            .onAppear{
                viewStore.send(.initial)
            }
        }
    }
    
//
//    func onSelectDatabaseAction(_ database:Int) -> Void {
//        Task {
//            let r = await redisInstanceModel.getClient().selectDB(database)
//            if r {
//                self.database = database
//                self.onChange?()
//            }
//        }
//    }
//
//    func queryDBList() -> Void {
//        Task {
//            let r = await redisInstanceModel.getClient().databases()
//            self.databases = r
//        }
//    }
}

