//
//  KeyValueRowEditorView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/9.
//

import SwiftUI

struct KeyValueRowEditorView: View {
    var body: some View {
        HStack {
            Text("key")
            Text("value")
        }
    }
}

struct KeyValueRowEditorView_Previews: PreviewProvider {
    static var previews: some View {
        KeyValueRowEditorView()
    }
}
