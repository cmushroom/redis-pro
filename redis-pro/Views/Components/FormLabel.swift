//
//  FormLabel.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/1/27.
//

import SwiftUI

struct FormLabel: View {
    var label:String
    var width:CGFloat?
    var required:Bool = false
    
    var body: some View {
        Text("\(required ? "* " : "")\(label):")
            .font(.body)
            .lineLimit(1)
            .frame(width: width, alignment: .trailing)
            
    }
}

struct FormLabel_Previews: PreviewProvider {
    static var previews: some View {
        FormLabel(label: "form label", width: 80, required: true)
    }
}
