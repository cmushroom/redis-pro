//
//  RedisKeysTable.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/7/9.
//

import Foundation
import SwiftUI
import Logging

struct RedisKeysTable: NSViewControllerRepresentable {
    @Binding var datasource: [RedisKeyModel]
    @Binding var selectRowIndex:Int
    var onChange: ((Int) -> Void)?
    var onClick: ((Int) -> Void)?
    
    var deleteAction: (_ index:Int) -> Void = {_ in }
    var renameAction: (_ index:Int) -> Void = {_ in }
    
    let logger = Logger(label: "redis-keys-table")
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    
    func makeNSViewController(context: Context) -> NSViewController {
        let controller = RedisKeysTableController()
        controller.setUp(action: self.onClick, deleteAction: self.deleteAction, renameAction: self.renameAction)
        return controller
    }
    
    
    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {
        guard let controller = nsViewController as? RedisKeysTableController else {return}
        controller.setDatasource(datasource)
        controller.tableView?.delegate = context.coordinator
        
        controller.arrayController.setSelectionIndex(self.selectRowIndex)
    }
    
    
    class Coordinator: NSObject, NSTableViewDelegate {
        
        var table: RedisKeysTable
        
        let logger = Logger(label: "client-list-table-coordinator")
        
        
        init(_ table: RedisKeysTable) {
            self.table = table
        
        }
        
        func tableViewSelectionIsChanging(_ notification: Notification) {
            guard let tableView = notification.object as? NSTableView else {return}
            guard self.table.datasource.count > 0 else {return}
            
            self.logger.info("redis key table Coordinator tableViewSelectionIsChanging, selectedRow: \(tableView.selectedRow)")
            
        }
        
        func tableViewSelectionDidChange(_ notification: Notification) {
            guard let tableView = notification.object as? NSTableView else {return}
            guard self.table.datasource.count > 0 else {return}
            
            self.logger.info("redis key table Coordinator tableViewSelectionDidChang, selectedRow: \(tableView.selectedRow)")
            
            self.table.selectRowIndex = tableView.selectedRow
            self.table.onChange?(self.table.selectRowIndex)
        }

        
    }
    
}
