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

    private let labelWidth:CGFloat = 160
    var store:StoreOf<SettingsStore>
    
    private let logger = Logger(label: "settings-view")
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            Form {
                VStack(alignment: .leading, spacing: 8) {
                    
                    Picker(selection: viewStore.binding(get: {$0.defaultFavorite}, send: SettingsStore.Action.setDefaultFavorite),
                           label: Text("Default Favorite:").frame(width: labelWidth, alignment: .trailing)
                    ) {
                        Section {
                            Text("Last Used").tag("last")
                        }
                        
                        ForEach(viewStore.redisModels, id: \.id) { item in
                            Text(item.name)
                        }
                    }
                    
                    Picker(selection: viewStore.binding(get: {$0.colorSchemeValue ?? ColorSchemeEnum.SYSTEM.rawValue}, send: SettingsStore.Action.setColorScheme),
                           label: Text("Appearance:").frame(width: labelWidth, alignment: .trailing)) {
                        ForEach(ColorSchemeEnum.allCases.map({$0.rawValue}), id: \.self) { item in
                            Text(verbatim: item)
                        }
                    }
                    
                    FormItemInt(label: "String Max Length", labelWidth: labelWidth, tips:"HELP_STRING_GET_RANGE_LENGTH", value: viewStore.binding(get: {$0.stringMaxLength}, send: SettingsStore.Action.setStringMaxLength))
                    
                    Toggle(isOn: viewStore.binding(get: {$0.fastPage}, send: SettingsStore.Action.setFastPage)) {
                        Text("Fast Page:")
                            .frame(width: labelWidth, alignment: .trailing)
                        }
                        .toggleStyle(.switch)
                        .help("HELP_FAST_PAGE")
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
