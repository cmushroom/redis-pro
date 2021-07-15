//
//  TextFieldController.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/7/15.
//
import Foundation
import Cocoa
import SwiftUI
import Logging

struct MNSTextField: NSViewRepresentable {
    @Binding var text: String
    var enable:Bool = true
    var editable:Bool = true
    var action: () throws -> Void = {}
    
    func makeNSView(context: NSViewRepresentableContext<Self>) -> NSTextField {
        let textField = NSTextField()
        
        textField.isEditable = editable
        textField.isEnabled = enable
        textField.isSelectable = true
        textField.delegate = context.coordinator

        return textField
    }
    func updateNSView(_ NSView: NSTextField, context: NSViewRepresentableContext<Self>) {
        
        if NSView.stringValue != self.text {
            NSView.stringValue = self.text
        }
        NSView.isEnabled = enable
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(text: $text)
    }
    
    final class Coordinator : NSObject, NSTextFieldDelegate {
//        var parent:MNSTextField
        var text: Binding<String>
        
        let logger = Logger(label: "text-field-coordinator")
        
//        init(_  parent:MNSTextField) {
//            self.parent = parent
//        }
        
        init(text: Binding<String>) {
            self.text = text
        }
        
        func controlTextDidChange(_ obj: Notification) {
            guard let textField = obj.object as? NSTextField else { return }
            
            logger.info("text field text change... \(textField.stringValue)")
//            self.parent.text = textField.stringValue
            self.text.wrappedValue = textField.stringValue
        }
        
        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if (commandSelector == #selector(NSResponder.insertNewline(_:))) {
                logger.info("text field on enter action, text: \(textView.string)")
                do {
//                    try parent.action()
                } catch {
                    MAlert.error(error)
                }
                
                return true
            }
            
            // return true if the action was handled; otherwise false
            return false
        }
        
    }
}
