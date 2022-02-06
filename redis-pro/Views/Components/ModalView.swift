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
        VStack(alignment: .center, spacing: 0) {
            HStack {
                Text(title)
                    .font(.body)
                Spacer()
            }
            .padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
            Rectangle().frame(height: 1)
                .padding(.horizontal, 0).foregroundColor(Color.gray.opacity(0.2))
            
            VStack(alignment: .leading, spacing: 0) {
                content
            }
            .padding(8)
            
            HStack(alignment: .center, spacing: 6) {
                Spacer()
                MButton(text: "Cancel", action: onCancel, keyEquivalent: .escape).keyboardShortcut(.cancelAction)
                MButton(text: "Submit", action: doAction, keyEquivalent: .return).keyboardShortcut(.defaultAction)
            }
            .padding(EdgeInsets(top: 0, leading: 8, bottom: 6, trailing: 8))
        }
        .frame(minWidth: MTheme.DIALOG_W, minHeight: MTheme.DIALOG_H)
        .padding(0)
    }
    
    func doAction() -> Void {
        presentation.wrappedValue.dismiss()
        try? action()
    }
    
    func onCancel() -> Void{
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
