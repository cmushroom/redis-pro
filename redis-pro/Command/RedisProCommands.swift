//
//  RedisProCommands.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/5/21.
//

import SwiftUI
import Cocoa
import Logging
import ComposableArchitecture

struct RedisProCommands: Commands {
    
    let logger = Logger(label: "commands")
    
    var body: some Commands {
        SidebarCommands()
        
        CommandGroup(replacing: CommandGroupPlacement.help) {
            CheckUpdateCommands()
            HomeCommands()
            AboutCommands()
        }
    }
}
