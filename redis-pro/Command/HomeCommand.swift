//
//  HomeCommand.swift
//  redis-pro
//
//  Created by chengpan on 2022/12/3.
//

import SwiftUI
import Foundation

struct HomeCommands: View {
    @Environment(\.openURL) var openURL
    
    var body: some View {
        Button("Home") {
            guard let url = URL(string: Constants.REPO_URL) else {
                return
            }
            openURL(url)
        }
    }
}
