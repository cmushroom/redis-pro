//
//  SecureTextField.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/7/20.
//

import SwiftUI

struct SecureTextField: View {
    @Binding var text: String
    @State private var isSecured: Bool = true
    var title:String = ""
    
    var body: some View {
        ZStack(alignment: .trailing) {
                    if isSecured {
                        SecureField(title, text: $text)
                    } else {
                        TextField(title, text: $text)
                    }
                    Button(action: {
                        isSecured.toggle()
                    }) {
                        Image(systemName: self.isSecured ? "eye.slash" : "eye")
                            .font(.system(size: 10))
                            .border(Color.clear, width: 0)
                            .background(Color.clear)
                            .shadow(color: .clear, radius: 0, x: 0, y: 0)
                            .buttonStyle(PlainButtonStyle())
                    }
                }
    }
}

struct SecureTextField_Previews: PreviewProvider {
    @State static var text:String = "aaa"
    static var previews: some View {
        VStack {
            SecureTextField(text: $text)
        }.padding(20)
    }
}
