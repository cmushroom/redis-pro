//
//  ZSetTableController.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/7/16.
//

import Foundation
import Cocoa
import Logging
import SwiftUI

class ZSetTableController: NSViewController {
    let logger = Logger(label: "hash-entry-table-controller")
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet var arrayController: NSArrayController!
    
    @objc dynamic var datasource: [RedisZSetItemModel] = []
    @IBAction func doubleAction(_ sender: NSTableView) {
        editAction?(sender.clickedRow)
    }
    
    var deleteAction: ((Int) -> Void)?
    var editAction: ((Int) -> Void)?
    
    override func viewDidLoad() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Edit", action: #selector(tableViewEditItemClicked(_:)), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Delete", action: #selector(tableViewDeleteItemClicked(_:)), keyEquivalent: ""))
        tableView.menu = menu
    }
        
    func setDatasource(_ datasource:[RedisZSetItemModel]) -> Void {
        self.datasource = datasource
    }
    
    func setUp(deleteAction: @escaping (_ index:Int) -> Void, editAction: @escaping (_ index:Int) -> Void) -> Void {
        self.deleteAction = deleteAction
        self.editAction = editAction
    }
    
    @objc private func tableViewEditItemClicked(_ sender: AnyObject) {
        logger.info("context menu rename index: \(tableView.clickedRow)")
        self.editAction?(tableView.clickedRow)
//        guard tableView.clickedRow >= 0 else { return }
    }
    
    @objc private func tableViewDeleteItemClicked(_ sender: AnyObject) {
        logger.info("context menu delete index: \(tableView.clickedRow)")
        self.deleteAction?(tableView.clickedRow)
    }
    
}



struct ZSetTable: NSViewControllerRepresentable {
    @Binding var datasource: [RedisZSetItemModel]
    @Binding var selectRowIndex:Int?
    var refresh:Int = 0
    
    
    var deleteAction: (_ index:Int) -> Void = {_ in }
    var editAction: (_ index:Int) -> Void = {_ in }
    
    let logger = Logger(label: "hash-table")
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    func makeNSViewController(context: Context) -> NSViewController {
        let controller = ZSetTableController()
        
        controller.setUp(deleteAction: deleteAction, editAction: editAction)
        
        return controller
    }
    
    
    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {
            
        guard let controller = nsViewController as? ZSetTableController else {return}
        controller.setDatasource(datasource)
        controller.tableView?.delegate = context.coordinator
        controller.arrayController.setSelectionIndex(selectRowIndex ?? -1)
//        controller.tableView.scrollRowToVisible(selectRowIndex)
    }
    
    class Coordinator: NSObject, NSTableViewDelegate {
        
        var table: ZSetTable
        
        let logger = Logger(label: "hash-table-coordinator")
        
        
        init(_ table: ZSetTable) {
            self.table = table
        
        }
        
        func tableViewSelectionIsChanging(_ notification: Notification) {
            
            guard let tableView = notification.object as? NSTableView else {return}
            guard self.table.datasource.count > 0 else {return}
            
            self.table.selectRowIndex = tableView.selectedRow == -1 ? nil : tableView.selectedRow

        }
    }
    
    
}
