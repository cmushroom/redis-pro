//
//  SettingsView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/6/9.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("User.colorSchemeValue")
    private var colorSchemeValue:String = ColorSchemeEnum.AUTO.rawValue
    @AppStorage("User.defaultFavorite")
    private var defaultFavorite:String = "last"
    @EnvironmentObject var redisInstanceModel:RedisInstanceModel
    @StateObject var redisFavoriteModel: RedisFavoriteModel = RedisFavoriteModel()
    
    private var labelWidth:CGFloat = 100
    
    var body: some View {
        Form {
            VStack(alignment: .leading, spacing: 8) {
            
                Picker(selection: $defaultFavorite,
                       label: Text("Default Favorite:").frame(width: labelWidth, alignment: .trailing)
                ) {
                    Section {
                        Text("Last Used").tag("last")
                    }
                    
                    ForEach(redisFavoriteModel.redisModels, id: \.id) { item in
                        Text(item.name)
                    }
                }
                Picker(selection: $colorSchemeValue,
                       label: Text("Appearance:").frame(width: labelWidth, alignment: .trailing)) {
                    ForEach(ColorSchemeEnum.allCases.map({$0.rawValue}), id: \.self) { item in
                        Text(verbatim: item)
                    }
                }
                Spacer()
            }
        }
        
        .onAppear {
            redisFavoriteModel.loadAll()
        }
        .navigationTitle("Preferences")
        .padding(30)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
