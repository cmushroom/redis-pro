//
//  DatabasePicker.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/5/10.
//

import SwiftUI

struct DatabasePicker: View {
    @EnvironmentObject var globalContext:GlobalContext
    @EnvironmentObject var redisInstanceModel:RedisInstanceModel
    @State private var databases:Int = 16
    @State var database:Int = 0
    @State var selection = 0
    var action: () -> Void = {}
    
    var body: some View {
//        Picker(selection: $selection, label: Text("􀡓 DB\(selection)")) {
//                    ForEach(0 ..< databases) { item in
//                            Text("DB\(item)")
//                        }
//                    }
//        .labelsHidden()
//                    .pickerStyle(DefaultPickerStyle())
  
        //                    Button("􀡓 DB\(database)", action: {})
        //                   Label("DB\(database)", systemImage: "cylinder.split.1x2")
        MenuButton(label:
                    Text("􀡓 DB\(database)")
//                    .foregroundColor(.primary)
//                    .disabled(false)
                    .font(.system(size: 10.0))
        ){
            ForEach(0 ..< databases) { item in
                Button("DB\(item)", action: {onSelectDatabaseAction(item)})
                    .font(.system(size: 10.0))
            }
        }
        .frame(width:50)
        .menuButtonStyle(BorderlessPullDownMenuButtonStyle())
        .onAppear{
            queryDBList()
        }
        
    }
    
    
    func onSelectDatabaseAction(_ database:Int) -> Void {
        do {
            try redisInstanceModel.getClient().selectDB(database)
            self.database = database
            
            action()
        } catch {
            globalContext.showError(error)
        }

    }
    
    func queryDBList() -> Void {
        do {
            self.databases = try redisInstanceModel.getClient().databases()
        } catch {
            globalContext.showError(error)
        }
    }
}


struct DatabasePicker_Previews: PreviewProvider {
    static var previews: some View {
        DatabasePicker()
    }
}

