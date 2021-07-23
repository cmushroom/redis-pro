//
//  MButton.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/1/28.
//

import SwiftUI
import Cocoa
import Foundation

struct SmallButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            //            .font(.body)
            .environment(\.sizeCategory, .extraSmall)
            .padding(EdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8))
            .foregroundColor(.primary)
            .background(Color(NSColor.controlBackgroundColor))
            .shadow(color: /*@START_MENU_TOKEN@*/.black/*@END_MENU_TOKEN@*/.opacity(0.2), radius: 1, x: 1, y: 1)
    }
}

struct MButton: View {
    @EnvironmentObject var globalContext:GlobalContext
    
    var text:String
    var action: () throws -> Void = {}
    var disabled:Bool = false
    var isConfirm:Bool = false
    var confirmTitle:String?
    var confirmMessage:String?
    var confirmPrimaryButtonText:String?
    var size:String = "normal"
    
    var isDefaultAction:Bool = false
    
    var width:CGFloat {
        100
    }
    
    var body: some View {
        NativeButton(title: text, keyEquivalent: isDefaultAction ? NativeButton.KeyEquivalent.return : nil, action: doAction, disabled: disabled)
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
                try action()
            } else {
                globalContext.confirm(confirmTitle ?? "", alertMessage: confirmMessage ?? "", primaryAction: action, primaryButton: confirmPrimaryButtonText ?? globalContext.primaryButtonText)
            }
        } catch {
            globalContext.showError(error)
        }
        
    }
    
    struct MButton_Previews: PreviewProvider {
        static var previews: some View {
            Group {
                VStack(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/, spacing: 8) {
                    Text(NSLocalizedString("hello", comment: "hello"))
                    Text(LocalizedStringKey("hello"))
                    Text("hello")
                    MButton(text: "Hello", action: {})
                    
                    MButton(text: "SmallButton ", action: {}).buttonStyle(SmallButtonStyle())
                    
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


@available(macOS 10.15, *)
struct NativeButton: NSViewRepresentable {
    var title: String?
    var attributedTitle: NSAttributedString?
    var keyEquivalent: KeyEquivalent?
    let action: () -> Void
    var icon:String?
    var disabled:Bool = false
    
    enum KeyEquivalent: String {
        case escape = "\u{1b}"
        case `return` = "\r"
    }
    
    func makeNSView(context: NSViewRepresentableContext<Self>) -> NSButton {
        let button = NSButton(title: "", target: nil, action: nil)

//        let button = NSButton(frame: CGRect(x: 0, y: 0, width: 140, height: 80))
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setContentHuggingPriority(.defaultHigh, for: .vertical)
        button.setContentHuggingPriority(.defaultHigh, for: .horizontal)
  
        button.frame.size.width = 180
//        button.wantsLayer = true
//        button.layer?.resize(withOldSuperlayerSize: CGSize(width: 180, height: 40))
//        button.setBoundsSize(NSSize(width: 180, height: 40))
//        button.frame = CGRect(x: 0, y: 0, width: 140, height: 80)
        
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
