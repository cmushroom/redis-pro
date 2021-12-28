//
//  NIntField.swift
//  redis-pro
//
//  Created by chengpan on 2021/12/5.
//

import SwiftUI
import Cocoa
import Logging


struct NIntField: NSViewRepresentable {
    @Binding var value: Int
    var placeholder: String
    var disable = false
    var onChange: (() -> Void)?
    var onCommit: (() -> Void)?
    
    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.integerValue = value
        textField.placeholderString = placeholder
        textField.delegate = context.coordinator
        
        textField.formatter = NumberHelper.intFormatter
        textField.isEnabled = !disable
        return textField
    }
    
    
    func updateNSView(_ nsView: NSTextField, context: Context) {
        nsView.integerValue = value
    }
    
    
    func makeCoordinator() -> Coordinator {
        Coordinator(with: self)
    }
    
    
    class Coordinator: NSObject, NSTextFieldDelegate {
        let parent: NIntField
        private var editing = false
        
        let logger = Logger(label: "int-field-coordinator")
        
        init(with parent: NIntField) {
            self.parent = parent
            super.init()
        }
        
        
        // MARK: - NSTextFieldDelegate Methods
        
        // change
        func controlTextDidChange(_ obj: Notification) {
            guard let textField = obj.object as? NSTextField else { return }
            
            if NumberHelper.isInt(textField.stringValue) {
                parent.value = textField.integerValue
            } else {
                textField.stringValue = String(parent.value)
            }
            editing = true
            parent.onChange?()
        }
        
        // commit
        func controlTextDidEndEditing(_ obj: Notification) {
            if editing {
                editing = false
                parent.onCommit?()
            }
        }
        
        
        func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
            logger.debug("on text field commit, value: \(parent.value)")
            parent.onCommit?()
            editing = false
            return true
        }
    }
    
}
