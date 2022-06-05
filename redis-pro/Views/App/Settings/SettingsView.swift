//
//  SettingsView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/6/9.
//

import Logging
import SwiftUI
import ComposableArchitecture

struct SettingsView: View {

    private var labelWidth:CGFloat = 100
    let store:Store<SettingsState, SettingsAction>
    
    private let logger = Logger(label: "settings-view")
    init(store:Store<SettingsState, SettingsAction>) {
        logger.info("settings view init")
        self.store = store
    }
    
    var body: some View {
        WithViewStore(store) { viewStore in
            Form {
                VStack(alignment: .leading, spacing: 8) {
                    
                    Picker(selection: viewStore.binding(get: {$0.defaultFavorite}, send: SettingsAction.updateDefaultFavorite),
                           label: Text("Default Favorite:").frame(width: labelWidth, alignment: .trailing)
                    ) {
                        Section {
                            Text("Last Used").tag("last")
                        }
                        
                        ForEach(viewStore.redisModels, id: \.id) { item in
                            Text(item.name)
                        }
                    }
                    Picker(selection: viewStore.binding(get: {$0.colorSchemeValue ?? ColorSchemeEnum.SYSTEM.rawValue}, send: SettingsAction.updateColorScheme),
//                    Picker(selection: $colorSchemeValue,
                           label: Text("Appearance:").frame(width: labelWidth, alignment: .trailing)) {
                        ForEach(ColorSchemeEnum.allCases.map({$0.rawValue}), id: \.self) { item in
                            Text(verbatim: item)
                        }
                    }
                    Spacer()
                }
            }
            .onAppear {
                viewStore.send(.initial)
            }
            .navigationTitle("Preferences")
            .padding(30)
        }
    }
}

//struct SettingsView_Previews: PreviewProvider {
//    static var previews: some View {
//        SettingsView()
//    }
//}
