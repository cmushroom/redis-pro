//
//  ColorSchemeEnum.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/6/9.
//

import Foundation
import SwiftUI

enum ColorSchemeEnum:String,CaseIterable{
    case AUTO = "auto"
    case DARK = "dark"
    case LIGHT = "light"
    
    static func getColorScheme(_ value:String) -> ColorScheme? {
        if ColorSchemeEnum.DARK.rawValue == value {
            return .dark
        } else if ColorSchemeEnum.LIGHT.rawValue == value {
            return .light
        } else {
            return .none
        }
    }
}
