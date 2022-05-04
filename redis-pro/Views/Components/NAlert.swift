//
//  Alert.swift
//  redis-pro
//
//  Created by chengpan on 2022/5/3.
//

import Logging
import SwiftUI
import ComposableArchitecture

struct NAlert: View {
    let store:Store<AppAlertState, AlertAction>
    
    var body: some View {
        HStack{
            EmptyView()
        }
        .frame(height: 0)
        .alert(self.store.scope(state: \.alert), dismiss: .clearAlert)
    }
}

//struct Alert_Previews: PreviewProvider {
//    static var previews: some View {
//        Alert()
//    }
//}
