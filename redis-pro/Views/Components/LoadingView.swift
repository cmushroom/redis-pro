//
//  NLoading.swift
//  redis-pro
//
//  Created by chengpan on 2022/5/3.
//

import Logging
import SwiftUI
import ComposableArchitecture

struct LoadingView: View {
    let store:StoreOf<AppContextStore>
    
    private var logger = Logger(label: "loading-view")
    
    init(_ store: Store<AppContextStore.State, AppContextStore.Action>) {
        logger.info("loading view init...")
        self.store = store
    }
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) {viewStore in
            HStack{
                EmptyView()
            }
            .frame(height: 0)
            .overlay(MSpin(loading: viewStore.loading))
        }
    }
}
