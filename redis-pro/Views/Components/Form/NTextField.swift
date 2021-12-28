//
//  NTextField.swift
//  redis-pro
//
//  Created by chenpanwang on 2021/12/2.
//

import Foundation
import SwiftUI
import Logging


enum NTextFieldType: String {
    case NORMAL = "normal"
    case PLAIN = "plain"
}

struct NTextField: NSViewRepresentable {
    @Binding var stringValue: String
    var placeholder: String
    var autoFocus = false
    var disabled = false
    var type: NTextFieldType = .NORMAL
    var tag: Int = 0
    var focusTag: Binding<Int>?
    var onChange: (() -> Void)?
    var onCommit: (() -> Void)?
    var onTabKeystroke: (() -> Void)?
    @State private var didFocus = false
    
    let logger = Logger(label: "text-field")
    
    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.stringValue = stringValue
        textField.placeholderString = placeholder
        textField.delegate = context.coordinator
    
        logger.info("text field init \(stringValue)")
//        print("text field init")
//        textField.alignment = .center
//        textField.bezelStyle = .roundedBezel
        textField.tag = tag
        textField.isEnabled = !disabled
        
        style(textField)
        return textField
    }
    
    
    func updateNSView(_ nsView: NSTextField, context: Context) {
        nsView.stringValue = stringValue
        nsView.isEnabled = !disabled
        
        if autoFocus && !didFocus {
            NSApplication.shared.mainWindow?.perform(
                #selector(NSApplication.shared.mainWindow?.makeFirstResponder(_:)),
                with: nsView,
                afterDelay: 0.0
            )
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                didFocus = true
            }
        }
        
        
        if let focusTag = focusTag {
            if focusTag.wrappedValue == nsView.tag {
                NSApplication.shared.mainWindow?.perform(
                    #selector(NSApplication.shared.mainWindow?.makeFirstResponder(_:)),
                    with: nsView,
                    afterDelay: 0.0
                )
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.focusTag?.wrappedValue = 0
                }
            }
        }
    }
    
    func style(_ textField:NSTextField) {
        if self.type == .NORMAL {
            
        } else if self.type == .PLAIN {
            textField.isBordered = false
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(with: self)
    }
    
    
    class Coordinator: NSObject, NSTextFieldDelegate {
        let parent: NTextField
        private var editing = false
        
        
        let logger = Logger(label: "text-field-coordinator")
        
        init(with parent: NTextField) {
            self.parent = parent
            super.init()
            
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(handleAppDidBecomeActive(notification:)),
                                                   name: NSApplication.didBecomeActiveNotification,
                                                   object: nil)
        }
        
        
        @objc
        func handleAppDidBecomeActive(notification: Notification) {
            if parent.autoFocus && !parent.didFocus {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    self.parent.didFocus = false
                }
            }
        }
        
        
        // MARK: - NSTextFieldDelegate Methods
        
        func controlTextDidChange(_ obj: Notification) {
            guard let textField = obj.object as? NSTextField else { return }
            parent.stringValue = textField.stringValue
            
            logger.debug("text field change, value: \(textField.stringValue)")
            editing = true
            parent.onChange?()
        }
        
        func controlTextDidEndEditing(_ obj: Notification) {
            guard let textField = obj.object as? NSTextField else { return }
            let value = textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            
            parent.stringValue = value
            logger.debug("text field end change, value: \(textField.stringValue)")
            if editing {
                editing = false
                parent.onChange?()
                parent.onCommit?()
            }
        }
        
        func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
            parent.stringValue = fieldEditor.string.trimmingCharacters(in: .whitespacesAndNewlines)
            
            logger.debug("on text field commit, text: \(parent.stringValue)")
            parent.onCommit?()
            editing = false
            return true
        }
        
//        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
//            if commandSelector == #selector(NSStandardKeyBindingResponding.insertTab(_:)) {
//                parent.onTabKeystroke?()
//                return true
//            }
//            return false
//        }
    }
    
    
}
