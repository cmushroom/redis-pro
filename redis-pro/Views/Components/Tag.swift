//
//  Tag.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/6.
//

import SwiftUI

struct Tag: View {
    var name:String
    var color:Color = Color.orange
    var bgColor:Color = Color.clear
    
    var body: some View {
        Text(name).foregroundColor(color)
            .background(bgColor)
    }
}

struct Tag_Previews: PreviewProvider {
    static var previews: some View {
        Tag(name: "tag")
    }
}
