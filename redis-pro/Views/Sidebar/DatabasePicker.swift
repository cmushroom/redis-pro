//
//  DatabasePicker.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/5/10.
//

import SwiftUI

struct DatabasePicker: View {
    @EnvironmentObject var redisInstanceModel:RedisInstanceModel
    @State private var databases:Int = 16
    @State var database:Int = 0
    @State var selection = 0
    var action: () -> Void = {}
    
    var body: some View {
        Menu(content: {
            ForEach(0 ..< databases) { item in
                Button("DB\(item)", action: {onSelectDatabaseAction(item)})
                    .font(.system(size: 10.0))
                    .foregroundColor(.primary)
            }
        }, label: {
            MLabel(name: "DB\(database)", icon: "cylinder.split.1x2").font(.system(size: 8))
        })
        .scaleEffect(0.9)
        .frame(width:56)
        .menuStyle(BorderlessButtonMenuStyle())
        .onAppear{
            queryDBList()
        }
    }
    
    
    func onSelectDatabaseAction(_ database:Int) -> Void {
        let _ = redisInstanceModel.getClient().selectDB(database).done({
            self.database = database
            action()
        })
    }
    
    func queryDBList() -> Void {
        let _ = redisInstanceModel.getClient().databases().done({r in
            self.databases = r
        })
    }
}


struct DatabasePicker_Previews: PreviewProvider {
    @State static var redisInstanceModel:RedisInstanceModel = RedisInstanceModel(redisModel: RedisModel())
    
    static var previews: some View {
        DatabasePicker().environmentObject(redisInstanceModel)
    }
}

