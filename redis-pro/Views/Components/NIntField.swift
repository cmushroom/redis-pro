//
//  NIntField.swift
//  redis-pro
//
//  Created by chengpan on 2021/12/5.
//

import SwiftUI
import Cocoa


struct NIntField: NSViewRepresentable {
    @Binding var value: Int
    var placeholder: String
    var autoFocus = false
    var disable = false
    var tag: Int = 0
    var focusTag: Binding<Int>?
    var onChange: (() -> Void)?
    var onCommit: (() -> Void)?
    var onTabKeystroke: (() -> Void)?
    @State private var didFocus = false
    
    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.integerValue = value
        textField.placeholderString = placeholder
        textField.delegate = context.coordinator
        
        textField.formatter = NumberHelper.intFormatter
//        textField.alignment = .center
//        textField.bezelStyle = .roundedBezel
        textField.tag = tag
        textField.isEnabled = !disable
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
        let parent: NIntField
        
        init(with parent: NIntField) {
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
        
        // change
        func controlTextDidChange(_ obj: Notification) {
            guard let textField = obj.object as? NSTextField else { return }
            
            if NumberHelper.isInt(textField.stringValue) {
                parent.value = textField.integerValue
            } else {
                textField.stringValue = String(parent.value)
            }
            
            parent.onChange?()
        }
        
        // commit
        func controlTextDidEndEditing(_ obj: Notification) {
            parent.onCommit?()
        }
        
        // editing
        func controlTextDidBeginEditing(_ obj: Notification) {
            
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
