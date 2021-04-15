//
//  StringEditView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/7.
//

import SwiftUI

struct StringEditorView: View {
    @State var text: String
    @State var editing:Bool = false
    
    
    func onSubmitAction() -> Void {
        print("on string value submit, text: \(text)")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4){
                // label
                Text("String value:")
                    .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
                
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
            .background(Color.white)
            
            // footer
            HStack(alignment: .center, spacing: 4) {
                Spacer()
                MButton(text: "Submit", action: onSubmitAction)
            }
            .padding(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
        }
        
    }
}
struct StringEditView_Previews: PreviewProvider {
    static var previews: some View {
        StringEditorView(text: "1234")
    }
}
