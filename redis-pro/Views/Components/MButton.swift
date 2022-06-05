//
//  MButton.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/1/28.
//

import SwiftUI
import Cocoa
import Foundation

struct MButton: View {
    var text:String
    var action: (() -> Void)?
    var disabled:Bool = false
    
    var keyEquivalent:KeyEquivalent?
    
    var body: some View {
        NButton(title: text, keyEquivalent: keyEquivalent, action: doAction, disabled: disabled)
            .onHover { inside in
                if !disabled && inside {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
    }
    
    var style:some PrimitiveButtonStyle {
        DefaultButtonStyle()
    }
    
    func doAction() -> Void {
        action?()
    }
    
}

enum KeyEquivalent: String {
    case escape = "\u{1b}"
    case `return` = "\r"
}

@available(macOS 10.15, *)
struct NButton: NSViewRepresentable {
    var title: String?
    var attributedTitle: NSAttributedString?
    var keyEquivalent: KeyEquivalent?
    let action: () -> Void
    var icon:String?
    var disabled:Bool = false
    
    func makeNSView(context: NSViewRepresentableContext<Self>) -> NSButton {
        let button = NSButton(title: "", target: nil, action: nil)

//        let button = NSButton(frame: CGRect(x: 0, y: 0, width: 140, height: 80))
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setContentHuggingPriority(.defaultHigh, for: .vertical)
        button.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        button.isEnabled = !disabled
        
        if icon != nil {
            button.image = NSImage(systemSymbolName: icon!, accessibilityDescription: nil)
            button.imagePosition = .imageLeft
        }
        
        button.font = button.font?.withSize(MTheme.FONT_SIZE_BUTTON)
        return button
    }
    
    func updateNSView(_ nsView: NSButton, context: NSViewRepresentableContext<Self>) {
        if attributedTitle == nil {
            nsView.title = title ?? ""
        }
        
        if title == nil {
            nsView.attributedTitle = attributedTitle ?? NSAttributedString(string: "")
        }
        
        nsView.keyEquivalent = keyEquivalent?.rawValue ?? ""
        nsView.isEnabled = !disabled
        nsView.onAction { _ in
            self.action()
        }
    }
}



// MARK: - Action closure for controls
private var controlActionClosureProtocolAssociatedObjectKey: UInt8 = 0

protocol ControlActionClosureProtocol: NSObjectProtocol {
    var target: AnyObject? { get set }
    var action: Selector? { get set }
}

private final class ActionTrampoline<T>: NSObject {
    let action: (T) -> Void
    
    init(action: @escaping (T) -> Void) {
        self.action = action
    }
    
    @objc
    func action(sender: AnyObject) {
        action(sender as! T)
    }
}

extension ControlActionClosureProtocol {
    func onAction(_ action: @escaping (Self) -> Void) {
        let trampoline = ActionTrampoline(action: action)
        self.target = trampoline
        self.action = #selector(ActionTrampoline<Self>.action(sender:))
        objc_setAssociatedObject(self, &controlActionClosureProtocolAssociatedObjectKey, trampoline, .OBJC_ASSOCIATION_RETAIN)
    }
}

extension NSControl: ControlActionClosureProtocol {}
