//
//  NSearchField.swift
//  redis-pro
//
//  Created by chenpanwang on 2021/12/16.
//

import SwiftUI
import Logging


struct NSearchField: NSViewRepresentable {
    @Binding var value: String
    var placeholder: String
    var disable = false
    var onChange: (() -> Void)?
    var onCommit: (() -> Void)?
    
    let logger = Logger(label: "search-field")
    
    func makeNSView(context: Context) -> NSSearchField {
        let textField = NSSearchField()
        textField.stringValue = value
        textField.placeholderString = placeholder
        textField.delegate = context.coordinator
    
        logger.info("search field init \(value)")
//        print("text field init")
//        textField.alignment = .center
//        textField.bezelStyle = .roundedBezel
//        textField.tag = tag
        textField.isEnabled = !disable
        
//        textField.bezelStyle = .roundedBezel
        return textField
    }
    
    
    func updateNSView(_ nsView: NSSearchField, context: Context) {
        nsView.stringValue = value
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(with: self)
    }
    
    
    class Coordinator: NSObject, NSSearchFieldDelegate {
        let parent: NSearchField
        
        
        let logger = Logger(label: "search-field-coordinator")
        
        init(with parent: NSearchField) {
            self.parent = parent
            super.init()
        }
        
        
        // MARK: - NSTextFieldDelegate Methods
        
        func controlTextDidChange(_ obj: Notification) {
            guard let textField = obj.object as? NSSearchField else { return }
            parent.value = textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            
            logger.info("search field change, value: \(textField.stringValue)")
            parent.onChange?()
        }
        
        func controlTextDidEndEditing(_ obj: Notification) {
            guard let textField = obj.object as? NSSearchField else { return }
            parent.value = textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            
            logger.info("search field end change, value: \(textField.stringValue)")
            parent.onChange?()
            parent.onCommit?()
        }
        
        func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
            logger.info("on search field commit")
            parent.value = fieldEditor.string.trimmingCharacters(in: .whitespacesAndNewlines)
            parent.onCommit?()
            return true
        }
    }
    
    
}
