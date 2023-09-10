//
//  FormText.swift
//  redis-pro
//
//  Created by chengpan on 2023/9/10.
//

import SwiftUI

struct FormText: View {
    var label: String?
    var value: String?
    
    var body: some View {
        HStack {
            Text(label ?? "")
                .foregroundColor(.secondary)
            Text(value ?? "")
                .foregroundColor(.primary)
        }
    }
}
