//
//  NSecureField.swift
//  redis-pro
//
//  Created by chengpan on 2021/12/12.
//
import Cocoa
import SwiftUI
import Logging

struct NSecureField: NSViewRepresentable {
    
    @Binding var value:String
    var placeholder:String?
    var onChange: (() -> Void)?
    var onCommit: (() -> Void)?
    
    func makeNSView(context: Context) -> NSSecureTextField {
        let textField = NSSecureTextField()
        textField.stringValue = value
        textField.placeholderString = placeholder
        textField.delegate = context.coordinator
//        textField.isBordered = true
//        textField.bezelStyle = .roundedBezel
        return textField
    }
    
    
    func updateNSView(_ nsView: NSSecureTextField, context: Context) {
        nsView.stringValue = value
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(with: self)
    }
    
    
    class Coordinator: NSObject, NSTextFieldDelegate {
        let parent: NSecureField
        
        
        let logger = Logger(label: "text-field-coordinator")
        
        init(with parent: NSecureField) {
            self.parent = parent
            super.init()
        }
        
        
        // MARK: - NSTextFieldDelegate Methods
        
        func controlTextDidChange(_ obj: Notification) {
            guard let textField = obj.object as? NSSecureTextField else { return }
            parent.value = textField.stringValue
            parent.onChange?()
        }
        
        func controlTextDidEndEditing(_ obj: Notification) {
            guard let textField = obj.object as? NSSecureTextField else { return }
            parent.value = textField.stringValue

            parent.onChange?()
        }
    }
    
}

//struct NSecureField_Previews: PreviewProvider {
//    static var previews: some View {
//        NSecureField()
//    }
//}
