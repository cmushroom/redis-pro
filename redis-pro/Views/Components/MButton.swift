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
    var action: (() throws -> Void)?
    var disabled:Bool = false
    var isConfirm:Bool = false
    var confirmTitle:String?
    var confirmMessage:String?
    var confirmPrimaryButtonText:String?
    
    var keyEquivalent:KeyEquivalent?
    
    var body: some View {
        NativeButton(title: text, keyEquivalent: keyEquivalent, action: doAction, disabled: disabled)
            //        Button(action: doAction) {
            //            Text(text)
            //                .font(.system(size: MTheme.FONT_SIZE_BUTTON))
            //                .multilineTextAlignment(.center)
            //                .lineLimit(1)
            //                .padding(.horizontal, 4.0)
            //        }
            //        .buttonStyle(BorderedButtonStyle())
            //            .disabled(disabled)
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
        do {
            if !isConfirm {
                try action?()
            } else {
                MAlert.confirm(confirmTitle ?? "", message: confirmMessage ?? "", primaryButton: confirmPrimaryButtonText ?? "Ok", primaryAction: primaryAction)
            }
        } catch {
            MAlert.error(error)
        }
    }
    
    func primaryAction() -> Void {
        try? action?()
    }
    
    struct MButton_Previews: PreviewProvider {
        static var previews: some View {
            Group {
                VStack(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/, spacing: 8) {
                    Text(NSLocalizedString("hello", comment: "hello"))
                    Text(LocalizedStringKey("hello"))
                    Text("hello")
                    MButton(text: "Hello", action: {})
                    
                    Button("default", action: {})
                    
                    Button("BorderedButtonStyle", action: {})
                    
                    Button("BorderlessButtonStyle", action: {}).buttonStyle(BorderlessButtonStyle())
                    
                    Button("LinkButtonStyle", action: {}).buttonStyle(LinkButtonStyle())
                    
                    Button("PlainButtonStyle", action: {}).preferredColorScheme(.dark).environment(\.sizeCategory, .small).buttonStyle(PlainButtonStyle())
                    
                    
                }
                .preferredColorScheme(.dark)
                .padding(20)
            }
        }
    }
}

enum KeyEquivalent: String {
    case escape = "\u{1b}"
    case `return` = "\r"
}

@available(macOS 10.15, *)
struct NativeButton: NSViewRepresentable {
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
