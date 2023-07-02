//
//  SearchBar.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/12.
//

import SwiftUI
import Logging
import ComposableArchitecture

struct SearchBar: View {
    
    @State private var keywords: String = ""
    var placeholder:String = "Search..."
    
    var onCommit: ((String) -> Void)?
    let logger = Logger(label: "search-bar")
    
    var body: some View {
        
        HStack {
            // Search text field
            NSearchField(value: $keywords, placeholder: placeholder, onCommit: doAction)
                .help("HELP_SEARCH_BAR")
        }
    }
    
    func doAction(keywords: String) -> Void {
        logger.info("on search bar action, keywords: \(keywords)")
        onCommit?(keywords)
    }
}
