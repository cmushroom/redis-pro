//
//  SearchBar.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/12.
//

import SwiftUI
import Logging

struct SearchBar: View {
    
    @State var keywords: String = ""
    @State var fuzzy: Bool = false
    @State var showFuzzy: Bool = false
    
    var action: (String) -> Void = {_ in }
    
    let logger = Logger(label: "search-bar")
    
    var body: some View {
        
        HStack {
            // Search text field
//            ZStack (alignment: .trailing) {
//
//            }
            TextField("Search...", text: $keywords, onEditingChanged: { isEditing in
            }, onCommit: doAction)
            .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 10))
            .textFieldStyle(PlainTextFieldStyle())
            .foregroundColor(.primary)
            
            
            MIcon(icon: "magnifyingglass", fontSize: 14, action: doAction)
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 4))
            
            if showFuzzy {
                Toggle("Fuzzy", isOn: $fuzzy)
            }
        }
        //            .padding(EdgeInsets(top: 8, leading: 6, bottom: 8, trailing: 6))
        // For magnifying glass and placeholder test
//        .foregroundColor(.secondary)
//        .background(Color.gray.opacity(0.2))
        .cornerRadius(4.0)
        
    }
    
    func doAction() -> Void {
        logger.info("on search bar action, keywords: \(keywords)")
        action(keywords)
    }
}

struct SearchBar_Previews: PreviewProvider {
    static var previews: some View {
        SearchBar()
    }
}
