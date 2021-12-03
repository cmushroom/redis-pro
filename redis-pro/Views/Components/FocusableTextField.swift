//
//  FocusableTextField.swift
//  redis-pro
//
//  Created by chenpanwang on 2021/12/2.
//

import Foundation
import SwiftUI

struct FocusableTextField: NSViewRepresentable {
    @Binding var stringValue: String
    var placeholder: String
    var autoFocus = false
    var tag: Int = 0
    var focusTag: Binding<Int>?
    var onChange: (() -> Void)?
    var onCommit: (() -> Void)?
    var onTabKeystroke: (() -> Void)?
    @State private var didFocus = false
    
    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.stringValue = stringValue
        textField.placeholderString = placeholder
        textField.delegate = context.coordinator
//        textField.alignment = .center
//        textField.bezelStyle = .roundedBezel
        textField.tag = tag
        return textField
    }
    
    
    func updateNSView(_ nsView: NSTextField, context: Context) {
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
    
    
    func makeCoordinator() -> Coordinator {
        Coordinator(with: self)
    }
    
    
    class Coordinator: NSObject, NSTextFieldDelegate {
        let parent: FocusableTextField
        
        init(with parent: FocusableTextField) {
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
            parent.onChange?()
        }
        
        func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
            parent.stringValue = fieldEditor.string
            parent.onCommit?()
            return true
        }
        
        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSStandardKeyBindingResponding.insertTab(_:)) {
                parent.onTabKeystroke?()
                return true
            }
            return false
        }
    }
    
    
}
