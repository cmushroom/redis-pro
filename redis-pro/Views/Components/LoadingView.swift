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
    private let logger = Logger(label: "loading-view")
    
    let store: StoreOf<AppContextStore>
    
    var body: some View {
        WithPerceptionTracking {
            HStack{
                EmptyView()
            }
            .frame(height: 0)
            .overlay(MSpin(loading: store.loading))
        }
    }
}
