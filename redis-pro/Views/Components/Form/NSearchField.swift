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
    @Binding var editing: Bool
    var placeholder: String
    var onCommit: ((String) -> Void)?
    
    private let logger = Logger(label: "search-field")
    
    func makeNSView(context: Context) -> NSSearchField {
        let textField = NSSearchField()
        textField.stringValue = value
        textField.placeholderString = placeholder
        textField.delegate = context.coordinator
    
        logger.info("search field init \(value)")
        
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
        private var editing = false
        
        
        let logger = Logger(label: "search-field-coordinator")
        
        init(with parent: NSearchField) {
            self.parent = parent
            super.init()
        }
        
        // MARK: - NSTextFieldDelegate Methods
//        func searchFieldDidStartSearching(textField: NSSearchField) {
//            logger.info("search field text change, value: \(textField.stringValue)")
//        }
//
//        
//        func searchFieldDidEndSearching(textField: NSSearchField) {
//            logger.info("search field text change, value: \(textField.stringValue)")
//        }
        
        
        func controlTextDidBeginEditing(_ obj: Notification) {
            if obj.object is NSSearchField {
                logger.info("NSearchField-begin editing...")
                parent.editing = true
            }
        }
        
        func controlTextDidChange(_ obj: Notification) {
            guard let textField = obj.object as? NSSearchField else { return }
            parent.value = textField.stringValue
            editing = true
            parent.editing = true
            logger.info("NSearchField-content change, value: \(textField.stringValue)")

        }

        func controlTextDidEndEditing(_ obj: Notification) {
            guard let textField = obj.object as? NSSearchField else { return }
            let value = textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            logger.info("NSearchField-end editing, value: \(value)")
            parent.value =  value
            if editing {
                editing = false
                parent.editing = false
                parent.onCommit?(value)
            }
        }
        
        // enter
        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            
            if (commandSelector == #selector(NSResponder.insertNewline(_:))) {
                 // Do something against ENTER key
                logger.debug("on search field enter commit, text: \(parent.value)")
                parent.onCommit?(parent.value)
                editing = false
                parent.editing = false
                
                return true
             }
            
            return false
        }
        
//        func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
//            let value = fieldEditor.string.trimmingCharacters(in: .whitespacesAndNewlines)
//            parent.value = value
//            logger.debug("on search field enter commit, text: \(parent.value)")
//            parent.onCommit?(value)
//            editing = false
//            return true
//        }
    }
    
    
}
