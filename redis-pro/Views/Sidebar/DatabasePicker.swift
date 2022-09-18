//
//  DatabasePicker.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/5/10.
//

import SwiftUI
import ComposableArchitecture

struct DatabasePicker: View {

    var store:Store<DatabaseState, DatabaseAction>
    
    var body: some View {
        WithViewStore(store) {viewStore in
            
            Menu(content: {
                ForEach(0 ..< viewStore.databases, id: \.self) { item in
                    Button("DB\(item)", action: { viewStore.send(.selectDB(item))})
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
 
}

