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
        nsView.integerValue = value
    }
    
    
    func makeCoordinator() -> Coordinator {
        Coordinator(with: self)
    }
    
    
    class Coordinator: NSObject, NSTextFieldDelegate {
        let parent: NIntField
        
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
            
            parent.onChange?()
        }
        
        // commit
        func controlTextDidEndEditing(_ obj: Notification) {
            parent.onCommit?()
        }
    }
    
}
