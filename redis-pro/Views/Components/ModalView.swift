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
        VStack(alignment: .center, spacing: 8) {
            HStack {
                Text(title)
                    .font(.title3)
                Spacer()
            }
            content
            HStack(alignment: .center, spacing: 8) {
                Spacer()
                MButton(text: "Cancel", action: onCancel).keyboardShortcut(.cancelAction)
                MButton(text: "Ok", action: doAction).keyboardShortcut(.defaultAction)
            }
        }
        .padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
    }
    
    func doAction() throws -> Void {
        presentation.wrappedValue.dismiss()
        try action()
    }
    
    func onCancel() throws -> Void{
        presentation.wrappedValue.dismiss()
    }
}

struct ModalView_Previews: PreviewProvider {
    static var previews: some View {
        ModalView("title", action: {print("modal view action")}) {
            Text("modal view")
        }
    }
}
