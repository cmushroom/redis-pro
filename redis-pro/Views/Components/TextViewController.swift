//
//  TextViewController.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/7/12.
//

import Foundation
import Cocoa
import SwiftUI
import Logging

class TextViewController: NSViewController {
    
    @objc dynamic var text: String = "hello"
    
    @IBOutlet var textView: NSTextView!
    
    var selectedRanges: [NSValue] = [] {
           didSet {
               guard selectedRanges.count > 0 else {
                   return
               }
               
               textView.selectedRanges = selectedRanges
           }
       }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.textView.enabledTextCheckingTypes = 0
        self.textView.layer?.cornerRadius = 4
    }
    
    func setText(_ text:String) -> Void {
        self.text = text
    }
    
}



struct MTextView: NSViewControllerRepresentable {
    @Binding var text:String
    
    let logger = Logger(label: "text-view")
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    
    func makeNSViewController(context: Context) -> NSViewController {
        let controller = TextViewController()
        return controller
    }
    
    
    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {
        guard let controller = nsViewController as? TextViewController else {return}
        controller.setText(text)
        controller.textView?.delegate = context.coordinator
        
        controller.selectedRanges = context.coordinator.selectedRanges
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        
        var parent: MTextView
        var selectedRanges: [NSValue] = []
        
        let logger = Logger(label: "text-view-coordinator")
        
        
        init(_ parent: MTextView) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            self.parent.text = textView.string
            self.selectedRanges = textView.selectedRanges
        }
    }
}

