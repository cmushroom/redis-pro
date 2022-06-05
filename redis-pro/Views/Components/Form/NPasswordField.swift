//
//  NPasswordField.swift
//  redis-pro
//
//  Created by chengpan on 2021/12/17.
//

import SwiftUI

struct NPasswordField: View {
    @Binding var value:String
    @State private var visible:Bool = false
    
    var body: some View {
        ZStack(alignment: .trailing) {
            if !visible {
//                NSecureField(value:$value, placeholder: "Password")
            } else {
                NTextField(stringValue:$value, placeholder: "Password")
            }
            Button(action: {
                visible.toggle()
            }) {
                Image(systemName: !self.visible ? "eye.slash" : "eye")
                    .accentColor(.gray)
            }
            .onHover { inside in
                if inside {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
            .padding(EdgeInsets(top: 0, leading: 2, bottom: 0, trailing: 2))
            .buttonStyle(PlainButtonStyle())
            .contentShape(Circle())
        }
    }
}

//struct NPasswordField_Previews: PreviewProvider {
//    static var previews: some View {
//        NPasswordField()
//    }
//}
