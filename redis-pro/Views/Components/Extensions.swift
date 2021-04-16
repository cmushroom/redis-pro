//
//  Extensions.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/13.
//

import SwiftUI

struct Extensions: View {
    @State var textField:String = ""
    
    var body: some View {
        VStack {
            TextField("test", text: $textField)
        }
    }
}

struct Extensions_Previews: PreviewProvider {
    static var previews: some View {
        Extensions()
    }
}
