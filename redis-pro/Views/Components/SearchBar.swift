//
//  SearchBar.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/12.
//

import SwiftUI
import Logging

struct SearchBar: View {
    
    @Binding var keywords: String
    @State var fuzzy: Bool = false
    @State var showFuzzy: Bool = false
    var placeholder:String = "Search..."
    
    var action: () throws -> Void = {}
    
    let logger = Logger(label: "search-bar")
    
    var body: some View {
        
        HStack {
            // Search text field
            MTextField(value: $keywords, placeholder: placeholder, suffix: "magnifyingglass", onCommit: doAction)
            
            if showFuzzy {
                Toggle("Fuzzy", isOn: $fuzzy)
            }
        }
    }
    
    func doAction() throws -> Void {
        logger.info("on search bar action, keywords: \(keywords)")
        try action()
    }
}

struct SearchBar_Previews: PreviewProvider {
    @State static var keywords:String = ""
    static var previews: some View {
        SearchBar(keywords: $keywords)
    }
}
