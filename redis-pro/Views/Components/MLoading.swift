//
//  Loading.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/5/20.
//

import SwiftUI

struct MLoading: View {
    var text:String = ""
    var loadingText:String = "Connecting..."
    var loading:Bool = false
    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            if loading {
                ProgressView()
                    .scaleEffect(x: 0.5, y: 0.5, anchor: .center)
                    .frame(width: 20, height: 20)
            }
            Text(loading ? loadingText : text)
                .font(.body)
                .multilineTextAlignment(.leading)
                .lineLimit(1)
        }
    }
}

struct MLoading_Previews: PreviewProvider {
    static var previews: some View {
        MLoading()
    }
}
