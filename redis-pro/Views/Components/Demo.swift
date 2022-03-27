//
//  Demo.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/6/21.
//

import SwiftUI
import AppKit
import Cocoa

struct Demo: View {
    @State var selection:Int?
    @State var value:String = ""
    @State var redisModel:RedisModel = RedisModel()
    @State var isSecured = true
    var body: some View {
        VStack(spacing: 10) {
            NTableView()
            
            ZStack(alignment: .trailing) {
                        if isSecured {
                            NSecureField(value:$value)
                        } else {
                            NTextField(stringValue:$value, placeholder: "pass")
                        }
                        Button(action: {
                            isSecured.toggle()
                        }) {
                            Image(systemName: self.isSecured ? "eye.slash" : "eye")
                                .accentColor(.gray)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .contentShape(Circle())
                    }
            
        }.padding(10)
    }
}

struct Demo_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            Demo()
                .frame(width: 600, height: 400, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
            Demo()
                .frame(width: 600, height: 400, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
        }
    }
}
