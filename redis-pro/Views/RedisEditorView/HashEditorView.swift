//
//  HashEditView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/9.
//

import SwiftUI

struct HashEditorView: View {
    @State var hash: Any?
    @State var editing:Bool = false
    
    let data = (1...100).map { "Item \($0)" }

       let columns = [
           GridItem(.adaptive(minimum: 80))
       ]
    
    func onSubmitAction() -> Void {
//        print("on string value submit, text: \(text)")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4){
                // label
                Text("String value:")
                    .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
                
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

struct HashEditView_Previews: PreviewProvider {
    static var previews: some View {
        HashEditorView()
    }
}
