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
    @State private var searchHistory: [String] = []
    @State private var isFocused: Bool = false
    var placeholder:String = "Search..."
    
    var onCommit: ((String) -> Void)?
    let logger = Logger(label: "search-bar")
    
    var body: some View {
        HStack {
            // Search text field
            if #available(macOS 12.0, *) {
                NSearchField(value: $keywords, editing: $isFocused, placeholder: placeholder, onCommit: doAction)
                    .help("HELP_SEARCH_BAR")
                    .overlay(alignment: .topLeading) {
                        // 下拉框展示历史搜索记录
                        if isFocused && !searchHistory.isEmpty {
                            let height = CGFloat(max(180, min(80, searchHistory.count * 20)))
                            
                            List {
                                ForEach(searchHistory.filter { $0.contains(keywords) || keywords.isEmpty }, id: \.self) { history in
                                    Text(history)
                                        .padding(0)
                                        .onTapGesture {
                                            // 点击历史记录时，将该条记录填充到搜索框中
                                            keywords = history
                                            isFocused = false // 关闭下拉框
                                            doAction(keywords: keywords)
                                        }
                                }
                            }
                            .frame(height: height) // 设置下拉框的高度
                            .padding(0)
                            .cornerRadius(4)
                            .offset(x: 0, y: 30)
                            .shadow(radius: 5)
                        }
                    }
            } else {
                NSearchField(value: $keywords, editing: $isFocused, placeholder: placeholder, onCommit: doAction)
                    .help("HELP_SEARCH_BAR")
            }
        }
        .zIndex(10)
        .onAppear {
            searchHistory = RedisDefaults.getSearchHistory()
        }
    }
    
    func doAction(keywords: String) -> Void {
        logger.info("on search bar action, keywords: \(keywords)")
        searchHistory.insert(keywords, at: 0)
        RedisDefaults.saveSearchHistory(history: searchHistory)
        onCommit?(keywords)
    }
}
