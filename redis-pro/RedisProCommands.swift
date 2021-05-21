//
//  RedisProCommands.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/5/21.
//

import SwiftUI

struct RedisProCommands: Commands {
    var body: some Commands {
        SidebarCommands()
        
        CommandGroup(replacing: CommandGroupPlacement.help) {
            Button("Check update") {
                if let url = URL(string: Constants.RELEASE_URL) {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }
}
