//
//  AboutView.swift
//  redis-pro
//
//  Created by chengpan on 2022/2/12.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 6) {
            Text("Github").font(.title3).bold()
            Link("redis-pro", destination: URL(string: "https://github.com/cmushroom/redis-pro")!)
           
            Text("感谢以下开源项目及项目维护者").font(.title3).bold()
            Link("RediStack", destination: URL(string: "https://github.com/Mordil/RediStack")!)
            Link("SwiftJSONFormatter", destination: URL(string: "https://github.com/luin/SwiftJSONFormatter")!)
            Link("Puppy", destination: URL(string: "https://github.com/sushichop/Puppy")!)
        }.padding(40)
            .frame(minWidth: 400, maxWidth: 1000, minHeight: 300, maxHeight: 800, alignment: .top)
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
