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
    var action: () ->Void = {print("on icon action...")}
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: fontSize))
                .padding(0)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { inside in
                    if inside {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
    }
    
    func onAction() -> Void {
        print("on icon action...")
    }
}

struct MIcon_Previews: PreviewProvider {
    static var previews: some View {
        MIcon(icon: "chevron.right").disabled(true)
    }
}
