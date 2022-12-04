//
//  CheckUpdateCommand.swift
//  redis-pro
//
//  Created by chengpan on 2022/12/3.
//

import SwiftUI
import Foundation

struct CheckUpdateCommands: View {
   var body: some View {
       Button("Check Update") {
           VersionManager().checkUpdate(isNoUpgradeHint: true)
       }
   }
}
