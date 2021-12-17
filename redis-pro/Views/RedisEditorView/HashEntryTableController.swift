//
//  HashEntryTableController.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/7/16.
//
import Foundation
import Cocoa
import Logging
import SwiftUI

class HashEntryTableController: NSViewController {
    let logger = Logger(label: "hash-entry-table-controller")
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet var arrayController: NSArrayController!
    @objc dynamic var datasource: [Any] = []
    
    var deleteAction: (_ index:Int) -> Void = {_ in }
    var editAction: (_ index:Int) -> Void = {_ in }
    
    override func viewDidLoad() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Edit", action: #selector(tableViewEditItemClicked(_:)), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Delete", action: #selector(tableViewDeleteItemClicked(_:)), keyEquivalent: ""))
        tableView.menu = menu
    }
        
    func setDatasource(_ datasource:[Any]) -> Void {
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

struct HashEntryTable: NSViewControllerRepresentable {
    @Binding var datasource: [Any]
    @Binding var selectRowIndex:Int
    var refresh:Int = 0
    
    
    var deleteAction: (_ index:Int) -> Void = {_ in }
    var editAction: (_ index:Int) -> Void = {_ in }
    
    let logger = Logger(label: "hash-table")
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    
    func makeNSViewController(context: Context) -> NSViewController {
        let controller = HashEntryTableController()
        
        controller.setUp(deleteAction: deleteAction, editAction: editAction)
        
        return controller
    }
    
    
    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {
            
        guard let controller = nsViewController as? HashEntryTableController else {return}
        controller.setDatasource(datasource)
        controller.tableView?.delegate = context.coordinator
        
        controller.arrayController.setSelectionIndex(selectRowIndex)
//        controller.tableView.scrollRowToVisible(selectRowIndex)
    }
    
    class Coordinator: NSObject, NSTableViewDelegate {
        
        var table: HashEntryTable
        
        let logger = Logger(label: "hash-table-coordinator")
        
        
        init(_ table: HashEntryTable) {
            self.table = table
        
        }
        
        func tableViewSelectionIsChanging(_ notification: Notification) {
            guard let tableView = notification.object as? NSTableView else {return}
            guard self.table.datasource.count > 0 else {return}
            
            self.table.selectRowIndex = tableView.selectedRow

        }
    }
    
    
}
