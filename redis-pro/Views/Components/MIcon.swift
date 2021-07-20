//
//  MIcon.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/7.
//

import SwiftUI

struct MIcon: View {
    var icon:String
    var fontSize:CGFloat = 10.0
    var disabled:Bool = false
    var action: () -> Void = {}
    
    var body: some View {
        
        Button(action: action) {
            Label("", systemImage: icon)
                .font(.system(size: fontSize))
                .labelStyle(IconOnlyLabelStyle())
                .frame(height: fontSize)
                .contentShape(Circle())
        }
        .foregroundColor(.primary)
        .contentShape(Circle())
        .buttonStyle(PlainButtonStyle())
        .disabled(disabled)
        .onHover { inside in
            if !disabled && inside {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
            
        }
    }
}

struct MIcon_Previews: PreviewProvider {
    static var previews: some View {
        MIcon(icon: "chevron.right").disabled(true)
    }
}
