//
//  ClientListTable.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/6/25.
//

import SwiftUI
import Foundation
import Cocoa

struct ClientListTable: NSViewControllerRepresentable {
    @Binding var list: [[String:String]]
    @Binding var selectRowIndex: Int
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    
    func makeNSViewController(context: Context) -> NSViewController {
        let controller = ClientListTableController()
        
//        controller.addObserver(<#T##observer: NSObject##NSObject#>, forKeyPath: <#T##String#>, options: <#T##NSKeyValueObservingOptions#>, context: <#T##UnsafeMutableRawPointer?#>)
        return controller
    }
    
    
    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {
        guard let controller = nsViewController as? ClientListTableController else {return}
        controller.setList(list)
        controller.tableView?.delegate = context.coordinator
    }
    
    class Coordinator: NSObject, NSTableViewDelegate {
        
        var table: ClientListTable
        
        init(_ table: ClientListTable) {
            self.table = table
        }
        
        func tableViewSelectionDidChange(_ notification: Notification) {
            guard let tableView = notification.object as? NSTableView else {return}
            guard self.table.list.count > 0 else {return}
            guard tableView.selectedRow >= 0 else {
                self.table.selectRowIndex = -1
                return
            }
            self.table.selectRowIndex = tableView.selectedRow
        }
        
    }
}
