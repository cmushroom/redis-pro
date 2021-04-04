//
//  FormLabel.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/1/27.
//

import SwiftUI

struct FormLabel: View {
    var label:String
    var body: some View {
        Text("\(label):")
            .font(.body)
            .lineLimit(1)
            .frame(width: 80.0, alignment: .trailing)
            
    }
}

struct FormLabel_Previews: PreviewProvider {
    static var previews: some View {
        FormLabel(label: "form label")
    }
}
