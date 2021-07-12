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
    @State static var text:String = "aaa"
    static var previews: some View {
        VStack(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/, spacing: 10) {
            
           MTextView(text: $text)
        }
        .frame(width: 200, height: 400, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
    }
}
