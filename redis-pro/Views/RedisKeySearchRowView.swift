//
//  RedisKeySearchRow.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/6.
//

import SwiftUI
import Logging

struct RedisKeySearchRowView: View {
    @Binding var value:String
    @State var fuzzy:Bool = false
    var body: some View {
        HStack {
            TextField("Please input keywords", text: $value)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            Button(action: onAction) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16.0))
                    .padding(0)
                
            }
            .buttonStyle(PlainButtonStyle())
            .padding(0)
            .onHover { inside in
                        if inside {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
            Toggle("Fuzzy", isOn: $fuzzy)
        }
    }
    
    
    func onAction() -> Void {
        logger.info("on search, keywords:\(value)")
    }
}

struct RedisKeySearchRow_Previews: PreviewProvider {
    @State static var v: String = "";
    
    static var previews: some View {
        RedisKeySearchRowView(value: $v)
    }
}
