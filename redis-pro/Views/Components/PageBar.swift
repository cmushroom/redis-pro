//
//  PageBar.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/12.
//

import ComposableArchitecture
import SwiftUI
import Logging

struct PageBar: View {
    @Perception.Bindable var store:StoreOf<PageStore>
    
    let logger = Logger(label: "page-bar")
    
    var body: some View {
            HStack(alignment:.center, spacing: 4) {
                if store.showTotal {
                    Text("Total: \(store.total)")
                        .font(MTheme.FONT_FOOTER)
                        .lineLimit(1)
                        .multilineTextAlignment(.trailing)
                }
                Picker("", selection: $store.size) {
                    Text("10").tag(10)
                    Text("50").tag(50)
                    Text("100").tag(100)
                    Text("200").tag(200)
                }
                .frame(width: 65)
                
                HStack(alignment:.center, spacing: 2) {
                    MIcon(icon: "chevron.left", disabled: !store.hasPrev, action: {store.send(.prevPage)})
                    Text("\(store.current)/\(store.totalPageText)")
                        .font(MTheme.FONT_FOOTER)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .layoutPriority(1)
                    MIcon(icon: "chevron.right", disabled: !store.hasNext, action: {store.send(.nextPage)})
                }
                .frame(minWidth: 60, idealWidth: 60)
            }
        
    }
    
}
