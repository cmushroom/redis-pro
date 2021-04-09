//
//  KeyValueRowEditorView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/9.
//

import SwiftUI

struct KeyValueRowEditorView: View {
    @State var text:String = ""
    @State var hashMap:[String: String] = ["testesttesttesttesttesttesttesttesttesttesttestt":"234243242343", "test1":"2342"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center , spacing: 4) {
                IconButton(icon: "plus", name: "Add", action: onDeleteAction)
                IconButton(icon: "trash", name: "Delete", action: onDeleteAction)
                Spacer()
            }
            .padding(EdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6))
            
            List() {
//                TextField("test", text: $text).environment(\.isEnabled, true)
//                    .textFieldStyle(PlainTextFieldStyle())
                LazyVGrid(columns: Array(repeating: GridItem(), count: 2), alignment: .leading, spacing: 20) {
                ForEach(hashMap.sorted(by: >), id:\.key) { key, value in
//                    Text(key)
//                        .multilineTextAlignment(.leading)
                    TextField("Key", text: $text)
                    Text(value)
                        .multilineTextAlignment(.leading)
                }
                }
            }
            .listStyle(PlainListStyle())
            .padding(.all, 0)
//                    .frame(minWidth: 100, maxWidth: .infinity, minHeight: 100, maxHeight: .infinity, alignment: .topLeading)

            
        }
    }
    
    func onDeleteAction() -> Void {
        print("hash field delete action...")
    }
}

struct KeyValueRowEditorView_Previews: PreviewProvider {
    static var previews: some View {
        KeyValueRowEditorView()
    }
}
