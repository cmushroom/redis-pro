//
//  IndexView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/8.
//

import SwiftUI
import Logging
import ComposableArchitecture

struct IndexView: View {
    @State var appState:AppState?
    
    private let logger = Logger(label: "index-view")
    
    
    init() {
        logger.info("index view init ...")
    }
    
    var body: some View {
        if let state = appState {
            let store: Store<AppState, AppAction> = Store(
                initialState: state,
                reducer: appReducer,
                environment:  .live(environment: AppEnvironment())
            )
            
            WithViewStore(store.scope(state: \.isConnect)) { viewStore in
                ZStack {
                    VStack {
                        if (viewStore.state) {
                            HomeView(store)
                        } else {
                            LoginView(store: store)
                        }
                        
                    }
                    
//                    AlertView(store.scope(state: \.appAlertState, action: AppAction.alertAction))
                    LoadingView(store.scope(state: \.globalState, action: AppAction.globalAction))
                }.onAppear {
                    GlobalStoreContext.setContext(appState?.id, store: store.scope(state: \.globalState, action: AppAction.globalAction))
                    viewStore.send(.initContext)
                }
            }
            
        } else {
            Spacer()
                .onAppear {
                    appState = AppState()
                }
        }
    }
}

//struct IndexView_Previews: PreviewProvider {
//    static var previews: some View {
//        IndexView()
//    }
//}
