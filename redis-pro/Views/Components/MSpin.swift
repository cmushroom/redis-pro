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
                HStack(alignment:.center, spacing: 8) {
                    ProgressView()
                    Text("Loading...")
                }
                .padding(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12))
                .frame(width: 200, height: 60)
                .background(Color.black.opacity(0.5))
                .cornerRadius(4)
                .shadow(color: .black.opacity(0.6), radius: 8, x: 4, y: 4)
            : nil
    }
    
    var body: some View {
        spin
        //            .sheet(isPresented: $loading) {
        //                ProgressView()
        //                    .background(Color.clear.opacity(0.1))
        //                    .progressViewStyle(CircularProgressViewStyle())
        //            }
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
