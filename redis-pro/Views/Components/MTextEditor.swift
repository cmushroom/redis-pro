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
    
    var body: some View {
        // text editor
        TextEditor(text: $text)
            .font(.body)
            .multilineTextAlignment(.leading)
            .padding(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
            .lineSpacing(1.5)
            .disableAutocorrection(true)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .border(Color.gray.opacity(editing ? 0.6 : 0.3), width: 1)
            .onHover { inside in
                self.editing = inside
            }
    }
}

struct MTextEditor_Previews: PreviewProvider {
    @State static var text:String = ""
    static var previews: some View {
        MTextEditor(text: $text)
    }
}
