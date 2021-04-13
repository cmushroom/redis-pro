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
    var placeholder:String = "Search..."
    
    
    var action: (String) -> Void = {_ in }
    
    let logger = Logger(label: "search-bar")
    
    var body: some View {
        
        HStack {
            // Search text field
            MTextField(value: $keywords, placeholder: placeholder, suffix: "magnifyingglass")
            
            if showFuzzy {
                Toggle("Fuzzy", isOn: $fuzzy)
            }
        }
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
