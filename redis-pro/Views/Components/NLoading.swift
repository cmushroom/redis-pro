//
//  NLoading.swift
//  redis-pro
//
//  Created by chengpan on 2022/5/3.
//

import Logging
import SwiftUI
import ComposableArchitecture

struct NLoading: View {
    let store:Store<LoadingState, LoadingAction>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            HStack{
                EmptyView()
            }
            .frame(height: 0)
            .overlay(MSpin(loading: viewStore.loading))
        }
    }
}
