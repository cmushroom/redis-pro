//
//  ListTableController.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/7/16.
//

import Foundation
import Cocoa
import Logging
import SwiftUI

class ListTableController: NSViewController {
    let logger = Logger(label: "list-table-controller")
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet var arrayController: NSArrayController!
    
    @objc dynamic var datasource: [String] = []
    
    var deleteAction: (_ index:Int) -> Void = {_ in }
    var editAction: (_ index:Int) -> Void = {_ in }
    
    override func viewDidLoad() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Edit", action: #selector(tableViewEditItemClicked(_:)), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Delete", action: #selector(tableViewDeleteItemClicked(_:)), keyEquivalent: ""))
        tableView.menu = menu
    }
    
    func setDatasource(_ datasource:[String]) -> Void {
        self.datasource = datasource
    }
    
    func setUp(deleteAction: @escaping (_ index:Int) -> Void, editAction: @escaping (_ index:Int) -> Void) -> Void {
        self.deleteAction = deleteAction
        self.editAction = editAction
    }
    
    @objc private func tableViewEditItemClicked(_ sender: AnyObject) {
        logger.info("context menu rename index: \(tableView.clickedRow)")
        self.editAction(tableView.clickedRow)
        //        guard tableView.clickedRow >= 0 else { return }
    }
    
    @objc private func tableViewDeleteItemClicked(_ sender: AnyObject) {
        logger.info("context menu delete index: \(tableView.clickedRow)")
        self.deleteAction(tableView.clickedRow)
    }
    
}



struct ListTable: NSViewControllerRepresentable {
    @Binding var datasource: [String]
    @Binding var selectRowIndex:Int?
    
    
    var deleteAction: (_ index:Int) -> Void = {_ in }
    var editAction: (_ index:Int) -> Void = {_ in }
    
    let logger = Logger(label: "hash-table")
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    
    func makeNSViewController(context: Context) -> NSViewController {
        let controller = ListTableController()
        
        controller.setUp(deleteAction: deleteAction, editAction: editAction)
        
        return controller
    }
    
    
    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {
            
        guard let controller = nsViewController as? ListTableController else {return}
        controller.setDatasource(datasource)
        controller.tableView?.delegate = context.coordinator
        
        controller.arrayController.setSelectionIndex(selectRowIndex ?? -1)
//        controller.tableView.scrollRowToVisible(selectRowIndex)
    }
    
    class Coordinator: NSObject, NSTableViewDelegate {
        
        var table: ListTable
        
        let logger = Logger(label: "hash-table-coordinator")
        
        
        init(_ table: ListTable) {
            self.table = table
        
        }
        
        func tableViewSelectionIsChanging(_ notification: Notification) {
            guard let tableView = notification.object as? NSTableView else {return}
            guard self.table.datasource.count > 0 else {return}
            
            self.table.selectRowIndex = tableView.selectedRow == -1 ? nil : tableView.selectedRow

        }
    }
    
    
}
