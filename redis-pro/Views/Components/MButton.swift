//
//  MButton.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/1/28.
//

import SwiftUI

struct MButton: View {
    @State private var showAlert = false
    @State private var msg:String = ""
    var text:String
    var action: () throws -> Void
    var type:String = ButtonTypeEnum.DEFAULT.rawValue
    
    
    var body: some View {
        Button(text, action: doAction)
//            .buttonStyle(style)
            .alert(isPresented: $showAlert) {
                Alert(title: Text("warnning"), message: Text(msg), dismissButton: .default(Text("OK")))
            }
    }
    
    var style:some PrimitiveButtonStyle {
        DefaultButtonStyle()
    }
    
    func doAction() -> Void {
        print("m button do action...")
        do {
            try action()
        } catch BizError.RedisError(let message) {
            print(message)
            showAlert = true
            msg = message
        } catch {
            showAlert = true
            msg = "system error: \(error)"
        }
    }
    
}

struct MButton_Previews: PreviewProvider {
    static var previews: some View {
        MButton(text: "button ", action: {
            print("hello")
        })
    }
}
