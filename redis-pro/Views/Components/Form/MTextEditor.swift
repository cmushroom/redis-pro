//
//  MTextEditor.swift
//  redis-pro
//  存在问题，自动转换双引号， 暂时使用 NSTextEditor
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
            .disableAutocorrection(true)
            .font(.body)
            .multilineTextAlignment(.leading)
            .padding(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
            .lineSpacing(1.5)
            .disableAutocorrection(true)
            .onHover { inside in
                self.editing = inside
            }
            .addBorder(Color.gray.opacity(!disabled && editing ?  0.4 : 0.2), width: 1, cornerRadius: 4)
    }
}


struct MTextEditor_Previews: PreviewProvider {
    @State static var text:String = ""
    static var previews: some View {
        MTextEditor(text: $text)
    }
}

extension NSTextView {
    open override var frame: CGRect {
        didSet {
            self.isAutomaticQuoteSubstitutionEnabled = false
        }
    }
}
