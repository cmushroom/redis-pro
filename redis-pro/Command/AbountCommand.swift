//
//  AbountCommand.swift
//  redis-pro
//
//  Created by chengpan on 2022/12/3.
//

import Foundation
import SwiftUI

struct AboutCommands: View {
    
    @Environment(\.openURL) var openURL
    var body: some View {
        Button("About") {
            guard let url = URL(string: "redis-pro://AboutView") else {
                return
            }
            openURL(url)
        }
    }
}
