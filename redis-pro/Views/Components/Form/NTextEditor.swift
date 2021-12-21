//
//  NTextEditor.swift
//  redis-pro
//
//  Created by chenpanwang on 2021/12/21.
//
import Cocoa
import SwiftUI
import Logging

struct NTextEditor: NSViewRepresentable {
    @Binding var value: String
//    var placeholder: String
    var disable = false
    var onChange: (() -> Void)?
    var onCommit: (() -> Void)?
    
    func makeNSView(context: Context) -> NSTextView {
        let textField = NSTextView()
        textField.string = value
//        textField.place = placeholder
        textField.delegate = context.coordinator

//        textField.isEnabled = !disable
        return textField
    }
    
    
    func updateNSView(_ nsView: NSTextView, context: Context) {
        nsView.string = value
    }
    
    
    func makeCoordinator() -> Coordinator {
        Coordinator(with: self)
    }
    
    
    class Coordinator: NSObject, NSTextViewDelegate {
        let parent: NTextEditor
        private var editing = false
        
        let logger = Logger(label: "text-editor-coordinator")
        
        init(with parent: NTextEditor) {
            self.parent = parent
            super.init()
        }
        
        
        // MARK: - NSTextFieldDelegate Methods
        
        // change
        func controlTextDidChange(_ obj: Notification) {
            guard let textField = obj.object as? NSTextView else { return }
            
            parent.value = textField.string
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

//struct NTextEditor_Previews: PreviewProvider {
//    static var previews: some View {
//        NTextEditor()
//    }
//}
