//
//  MButton.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/1/28.
//

import SwiftUI

struct MButton: View {
    @EnvironmentObject var globalContext:GlobalContext
    var text:String
    var action: () throws -> Void = {}
    var isConfirm:Bool = false
    var disabled:Bool = false
    var type:String = ButtonTypeEnum.DEFAULT.rawValue
    
    
    var body: some View {
        Button(text, action: doAction)
            .disabled(disabled)
            .onHover { inside in
                    if !disabled && inside {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
            }
    }
    
    var style:some PrimitiveButtonStyle {
        DefaultButtonStyle()
    }
    
    func doAction() -> Void {
        print("m button do action...")
        do {
            try action()
        } catch {
            globalContext.showError(error)
        }
        
    }
    
    struct MButton_Previews: PreviewProvider {
        static var previews: some View {
            MButton(text: "button ", action: {
            })
        }
    }
}
