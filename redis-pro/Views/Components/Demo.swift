//
//  Demo.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/6/21.
//

import SwiftUI
import AppKit

struct Demo: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct Demo_Previews: PreviewProvider {
    @State static var selection:Int?
    static var previews: some View {
        VStack(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/, spacing: 10) {
            
            List(selection: $selection) {
                HStack(alignment: .center, spacing: 100) {
                    Text("a").tag(4)
                    Text("a").tag(5)
                    Text("a").tag(5)
                    Spacer()
                }
                .tag(4)
                
                    HStack(alignment: .center, spacing: 10) {
                        Text("a").tag(4)
                        Text("a").tag(5)
                        Text("a").tag(5)
                        Spacer()
                    }
                    .tag(5)
            }.frame(width: 200)
        }
        .frame(width: 200, height: 400, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
    }
}
