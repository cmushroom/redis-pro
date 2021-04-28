//
//  ModalView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/28.
//

import SwiftUI

struct ModalView<Content: View>: View {
    @Environment(\.presentationMode) var presentation
    var title: String
    var action: () throws -> Void
    var content: Content
    
    
    init(_ title:String, action: @escaping () throws -> Void, @ViewBuilder content: () -> Content) {
        self.title = title
        self.action = action
        self.content = content()
    }
    
    var body: some View {
        VStack {
            content
            HStack(alignment: .center, spacing: 4) {
                Spacer()
                MButton(text: "Cancel")
                MButton(text: "Ok", action: doAction)
            }
        }
    }
    
    func doAction() throws -> Void {
        try action()
        presentation.animation()
    }
}

struct ModalView_Previews: PreviewProvider {
    static var previews: some View {
        ModalView("modal", action: {print("modal view action")}) {
            Text("modal view")
        }
    }
}
