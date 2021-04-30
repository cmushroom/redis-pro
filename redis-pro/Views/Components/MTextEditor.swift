//
//  MTextEditor.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/29.
//

import SwiftUI

struct MTextEditor: View {
    @Binding var text:String
    @State private var editing:Bool = false
    @State private var disabled:Bool = false
    
    var body: some View {
        // text editor
        TextEditor(text: $text)
            .font(.body)
            .multilineTextAlignment(.leading)
            .padding(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
            .lineSpacing(1.5)
            .disableAutocorrection(true)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .onHover { inside in
                self.editing = inside
            }
            .cornerRadius(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4).stroke(Color.gray.opacity(!disabled && editing ?  0.4 : 0.2), lineWidth: 1)
                )
    }
}

struct MTextEditor_Previews: PreviewProvider {
    @State static var text:String = ""
    static var previews: some View {
        MTextEditor(text: $text)
    }
}
