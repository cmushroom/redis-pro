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
    private var logger = Logger(label: "loading-view")
    
    @Dependency(\.appContext) var appContext
    
    init() {
        logger.info("loading view init...")
    }
    
    var body: some View {
        WithViewStore(appContext, observe: { $0 }) {viewStore in
            HStack{
                EmptyView()
            }
            .frame(height: 0)
            .overlay(MSpin(loading: viewStore.loading))
        }
    }
}
