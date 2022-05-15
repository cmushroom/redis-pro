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
    let store:Store<LoadingState, LoadingAction>
    
    private var logger = Logger(label: "loading-view")
    
    init(_ store: Store<LoadingState, LoadingAction>) {
        logger.info("loading view init...")
        self.store = store
        LoadingUtil.initial(store)
    }
    
    
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


class LoadingUtil {
    var store:Store<LoadingState, LoadingAction>
    var viewStore: ViewStore<LoadingState, LoadingAction>
    
    static var instance:LoadingUtil?
    
    private var logger = Logger(label: "loading-util")
    
    init(_ store: Store<LoadingState, LoadingAction>) {
        logger.info("loading util init...")
        
        self.store = store
        self.viewStore = ViewStore(store)
    }
    
    static func initial(_ store: Store<LoadingState, LoadingAction>) {
        if instance != nil {
            return
        }
        
        LoadingUtil.instance = .init(store)
    }
    
    static func show() {
        DispatchQueue.main.async {
            instance?.viewStore.send(.show)
        }
        
    }
    static func hide() {
        DispatchQueue.main.async {
        instance?.viewStore.send(.hide)
        }
    }
    
}
