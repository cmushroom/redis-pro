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
    @Perception.Bindable var store:StoreOf<SettingsStore>
    
    private let logger = Logger(label: "settings-view")
    
    var body: some View {
        WithPerceptionTracking {
            Form {
                VStack(alignment: .leading, spacing: 8) {
                    
                    Picker(selection: $store.defaultFavorite.sending(\.setDefaultFavorite),
                           label: Text("Default Favorite:").frame(width: labelWidth, alignment: .trailing)
                    ) {
                        Section {
                            Text("Last Used").tag("last")
                        }
                        
                        ForEach(store.redisModels, id: \.id) { item in
                            Text(item.name)
                        }
                    }
                    
                    Picker(selection: $store.colorSchemeValue.sending(\.setColorScheme),
                           label: Text("Appearance:").frame(width: labelWidth, alignment: .trailing)) {
                        ForEach(ColorSchemeEnum.allCases.map({$0.rawValue}), id: \.self) { item in
                            Text(verbatim: item)
                        }
                    }
                    
                    FormItemInt(label: "String Max Length", labelWidth: labelWidth, tips:"HELP_STRING_GET_RANGE_LENGTH", value: $store.stringMaxLength.sending(\.setStringMaxLength))
                    
                    Toggle(isOn: $store.fastPage.sending(\.setFastPage)) {
                        Text("Fast Page:")
                            .frame(width: labelWidth, alignment: .trailing)
                    }
                    .toggleStyle(.switch)
                    .help("HELP_FAST_PAGE")
                    
                    
                    FormItemInt(label: "Search History", labelWidth: labelWidth, tips:"HELP_SEARCH_HISTORY_SIZE", value: $store.searchHistorySize.sending(\.setSearchHistorySize))
                    
                    Spacer()
                }
            }
            .onAppear {
                store.send(.initial)
            }
            .navigationTitle("Preferences")
            .padding(30)
        }
        
    }
}
