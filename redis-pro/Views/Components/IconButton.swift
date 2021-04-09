//
//  IconButton.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/9.
//

import SwiftUI

struct IconButton: View {
    @State private var showAlert = false
    @State private var msg:String = ""
    var icon:String
    var name:String
    
    var action: () throws -> Void = {
        print("icon button action...")
    }
    
    var body: some View {
        Button(action: doAction) {
            HStack(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/, spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 12.0))
                    .padding(0)
                Text(name)
            }
        }
        .buttonStyle(BorderedButtonStyle())
        .alert(isPresented: $showAlert) {
            Alert(title: Text("warnning"), message: Text(msg), dismissButton: .default(Text("OK")))
        }
    }
    
    
    func doAction() -> Void {
        print("icon button do action...")
        do {
            try action()
        } catch {
            showAlert = true
            msg = "system error: \(error)"
        }
    }
}

struct IconButton_Previews: PreviewProvider {
    static var previews: some View {
        IconButton(icon: "plus", name: "Add")
    }
}
