//
//  PageBar.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/12.
//

import SwiftUI
import Logging
import ComposableArchitecture

struct PageBar: View {
    var store:StoreOf<PageStore>
    
    let logger = Logger(label: "page-bar")
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
    
            HStack(alignment:.center, spacing: 4) {
                if viewStore.showTotal {
                    Text("Total: \(viewStore.total)")
                        .font(MTheme.FONT_FOOTER)
                        .lineLimit(1)
                        .multilineTextAlignment(.trailing)
                }
                Picker("", selection: viewStore.$size) {
                    Text("10").tag(10)
                    Text("50").tag(50)
                    Text("100").tag(100)
                    Text("200").tag(200)
                }
                .frame(width: 65)
                
                HStack(alignment:.center, spacing: 2) {
                    MIcon(icon: "chevron.left", disabled: !viewStore.hasPrev, action: {viewStore.send(.prevPage)})
                    Text("\(viewStore.current)/\(viewStore.totalPageText)")
                        .font(MTheme.FONT_FOOTER)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .layoutPriority(1)
                    MIcon(icon: "chevron.right", disabled: !viewStore.hasNext, action: {viewStore.send(.nextPage)})
                }
                .frame(minWidth: 60, idealWidth: 60)
            }
            
        }
    }
    
}

//struct PageBar_Previews: PreviewProvider {
//    static var previews: some View {
//        PageBar(page: Page())
//    }
//}
