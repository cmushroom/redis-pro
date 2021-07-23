//
//  MLabel.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/7/20.
//

import SwiftUI

struct MLabel: View {
    var name:String
    var icon:String
    var size: MLabelSize = .M
    
    var textSize:CGFloat {
        if size == .M {
            return  MTheme.FONT_SIZE_BUTTON
        } else if size == .L {
            return  MTheme.FONT_SIZE_BUTTON_L
        }
        
        return MTheme.FONT_SIZE_BUTTON_S
    }
    var iconSize:CGFloat {
        if size == .M {
            return  MTheme.FONT_SIZE_BUTTON_ICON
        } else if size == .L {
            return  MTheme.FONT_SIZE_BUTTON_ICON_L
        }
        
        return MTheme.FONT_SIZE_BUTTON_ICON_S
    }
    
    var body: some View {
        Label {
            Text(name)
                .font(.system(size: textSize))
        } icon: {
            Image(systemName: icon)
                .font(.system(size: iconSize))
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 2, trailing: -6))
        }
        .foregroundColor(.primary)
    }
}

enum MLabelSize {
    case S
    case M
    case L
}

struct MLabel_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            MLabel(name: "Add", icon: "plus")
            MLabel(name: "DB\(1)", icon: "cylinder.split.1x2", size: .S)
        }
    }
}
