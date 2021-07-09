//
//  ClientListTable.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/6/25.
//

import SwiftUI
import Foundation
import Cocoa
import Logging

struct ClientListTable: NSViewControllerRepresentable {
    @Binding var list: [ClientModel]
    @Binding var selectRowIndex: Int
    
    let logger = Logger(label: "client-list-table")
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    
    func makeNSViewController(context: Context) -> NSViewController {
        let controller = ClientListTableController()
        
        return controller
    }
    
    
    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {
//        logger.info("client list table updateNSViewController, selectRowIndex: \(selectRowIndex)")
            
        guard let controller = nsViewController as? ClientListTableController else {return}
        controller.setList(list)
        controller.tableView?.delegate = context.coordinator
        
        guard selectRowIndex >= 0 else {
            controller.arrayController.removeSelectionIndexes([0])
            return
        }
        controller.arrayController.setSelectionIndex(selectRowIndex)
        controller.tableView.scrollRowToVisible(selectRowIndex)
    }
    
    class Coordinator: NSObject, NSTableViewDelegate {
        
        var table: ClientListTable
        
        let logger = Logger(label: "client-list-table-coordinator")
        
        
        init(_ table: ClientListTable) {
            self.table = table
        
        }
        
        func tableViewSelectionDidChange(_ notification: Notification) {
            guard let tableView = notification.object as? NSTableView else {return}
            guard self.table.list.count > 0 else {return}
            
            self.logger.info("client list table Coordinator tableViewSelectionDidChange, selectedRow: \(tableView.selectedRow)")
            guard tableView.selectedRow >= 0 else {
                self.table.selectRowIndex = -1
                return
            }
            self.table.selectRowIndex = tableView.selectedRow
        }
        
    }
}
