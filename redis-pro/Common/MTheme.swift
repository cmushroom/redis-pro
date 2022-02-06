//
//  ColorEnum.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/6.
//

import Foundation
import SwiftUI

struct MTheme {
//    static var PRIMARY:Color = Color(red: 0.1, green: 0.1, blue: 0.1)
    static var PRIMARY:Color = Color.gray
    
    static var CORNER_RADIUS:CGFloat = 2
    
    static var DIALOG_W:CGFloat = 640
    static var DIALOG_H:CGFloat = 400
    
//    spacing
    static var H_SPACING:CGFloat = 6
    static var H_SPACING_L:CGFloat = 10
    static var V_SPACING:CGFloat = 6
    
    static var HEADER_PADDING:EdgeInsets = EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0)
    
    // font size
    static var FONT_SIZE_BUTTON:CGFloat = 12
    static var FONT_SIZE_BUTTON_ICON:CGFloat = 11
    static var FONT_SIZE_BUTTON_S:CGFloat = 10
    static var FONT_SIZE_BUTTON_ICON_S:CGFloat = 9
    static var FONT_SIZE_BUTTON_L:CGFloat = 14
    static var FONT_SIZE_BUTTON_ICON_L:CGFloat = 12
    
    static var FONT_FOOTER:Font = .footnote
    
    // table cell null
    static var NULL_STRING = "-"
}
