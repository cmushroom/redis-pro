//
//  KeyObjectBar.swift
//  redis-pro
//
//  Created by chengpan on 2023/7/30.
//

import SwiftUI
import Logging
import ComposableArchitecture

struct KeyObjectBar: View {
    var store:StoreOf<KeyObjectStore>
    
    let logger = Logger(label: "key-object-bar")
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            FormText(label: "Object Encoding:", value: viewStore.encoding)
            .padding(EdgeInsets(top: 0, leading: MTheme.H_SPACING, bottom: 0, trailing: MTheme.H_SPACING))
        
        }
    }
}
