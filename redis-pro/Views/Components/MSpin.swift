//
//  MSpin.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/5/21.
//

import SwiftUI
import AppKit
import Foundation

struct MSpin: View {
    var loading:Bool = false
    
    var spin: some View {
        loading ?
                VStack(alignment:.center, spacing: 8) {
                    ProgressView()
                    Text("Loading...")
                }
                .padding(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12))
                .frame(width: 140, height: 120)
                .background(Color.black.opacity(0.4))
                .cornerRadius(8)
                .shadow(color: .black.opacity(0.6), radius: 8, x: 4, y: 4)
                .colorScheme(.dark)
            : nil
    }
    
    var body: some View {
        spin
    }
}

struct MSpin_Previews: PreviewProvider {
    @State static var loading:Bool = true
    static var previews: some View {
        
        HStack {
            MSpin(loading: loading)
        }
        .colorScheme(.dark)
            .frame(width: 500, height: 400, alignment: .center)
    }
}
