//
//  PageBar.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/12.
//

import SwiftUI
import Logging

struct PageBar: View {
    @State var total:Int = 0
    @State var size:Int = 50
    @State var current:Int = 1

    var totalPage:Int {
        total / size
    }
    var hasPrevPage:Bool {
        totalPage > 1 && current > 1
    }
    var hasNextPage:Bool {
        totalPage > 1 && current < totalPage
    }
    
    let logger = Logger(label: "page-bar")
    
    var body: some View {
        HStack(alignment:.center) {
            Spacer()
            Text("Keys:\(total)")
                .font(.footnote)
                .padding(.leading, 4.0)
                
//            Spacer()
            Picker("", selection: $size) {
                Text("50").tag(50)
                Text("100").tag(100)
                Text("200").tag(200)
                Text("500").tag(500)
            }
            .font(/*@START_MENU_TOKEN@*/.footnote/*@END_MENU_TOKEN@*/)
            .frame(width: 70)
            HStack(alignment:.center) {
                MIcon(icon: "chevron.left").disabled(hasPrevPage)
                Text("\(current)/\(totalPage)")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
//                    .layoutPriority(1)
                MIcon(icon: "chevron.right").disabled(hasNextPage)
            }
            .layoutPriority(1)
        }
        .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
    }
}

struct PageBar_Previews: PreviewProvider {
    static var previews: some View {
        PageBar()
    }
}
