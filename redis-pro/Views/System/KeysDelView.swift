//
//  DeletePatternView.swift
//  redis-pro
//
//  Created by chengpan on 2023/12/10.
//

import SwiftUI
import Logging
import ComposableArchitecture

private let logger = Logger(label: "keys-del-view")

struct KeysDelView: View {
    var store:StoreOf<KeysDelStore>

    var body: some View {
        WithViewStore(self.store, observe: { $0 }) {viewStore in
            VStack(alignment: .leading, spacing: MTheme.V_SPACING) {
                // header
                HStack(alignment: .center, spacing: MTheme.H_SPACING) {
                    SearchBar(placeholder: "Search...", onCommit: {viewStore.send(.search($0))})
                    PageBar(store: store.scope(state: \.pageState, action: KeysDelStore.Action.pageAction))
                    Spacer()
                }
                
                NTableView(store: store.scope(state: \.tableState, action: KeysDelStore.Action.tableAction))
                
                // footer
                HStack(alignment: .center, spacing: MTheme.H_SPACING_L) {
                    Spacer()
                    IconButton(icon: "trash", name: "Delete", disabled: viewStore.tableState.isEmpty, action: {viewStore.send(.doDel)})
                }
                .padding(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
            }.onAppear {
            }
        }
    }
    
}

//#Preview {
//    DeletePatternView()
//}
