//
//  RedisConfigTableController.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/7/21.
//

import Foundation
import Cocoa
import Logging
import SwiftUI

class RedisConfigTableController: NSViewController {
    let logger = Logger(label: "redis-config-table")
    @objc dynamic var datasource: [RedisConfigItemModel] = [RedisConfigItemModel]()
    
    @IBOutlet var arrayController: NSArrayController!
    @IBOutlet weak var tableView: NSTableView!
    
    var editAction: (_ index:Int) -> Void = {_ in }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Edit", action: #selector(tableViewEditItemClicked(_:)), keyEquivalent: ""))
        tableView.menu = menu
    }
    
    func setDatasource(_ datasource:[RedisConfigItemModel]) -> Void {
        self.datasource = datasource
    }
    
    func setUp(editAction: @escaping (_ index:Int) -> Void) -> Void {
        self.editAction = editAction
    }
    
    @objc private func tableViewEditItemClicked(_ sender: AnyObject) {
        logger.info("context menu rename index: \(tableView.clickedRow)")
        self.editAction(tableView.clickedRow)
    }
}


struct RedisConfigTable: NSViewControllerRepresentable {
    @Binding var datasource: [RedisConfigItemModel]
    @Binding var selectRowIndex:Int?
    var refresh:Int = 0
    
    var editAction: (_ index:Int) -> Void = {_ in }
    
    let logger = Logger(label: "redis-config-table")
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    
    func makeNSViewController(context: Context) -> NSViewController {
        let controller = RedisConfigTableController()
        
        controller.setUp(editAction: editAction)
        return controller
    }
    
    
    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {
            
        guard let controller = nsViewController as? RedisConfigTableController else {return}
        controller.setDatasource(datasource)
        controller.tableView?.delegate = context.coordinator
        
        controller.arrayController.setSelectionIndex(selectRowIndex ?? -1)
//        controller.tableView.scrollRowToVisible(selectRowIndex)
    }
    
    class Coordinator: NSObject, NSTableViewDelegate {
        
        var table: RedisConfigTable
        
        let logger = Logger(label: "redis-config-table-coordinator")
        
        
        init(_ table: RedisConfigTable) {
            self.table = table
        
        }
        
        func tableViewSelectionIsChanging(_ notification: Notification) {
            guard let tableView = notification.object as? NSTableView else {return}
            guard self.table.datasource.count > 0 else {return}
            
            self.table.selectRowIndex = tableView.selectedRow == -1 ? nil : tableView.selectedRow

        }
    }
    
    
}
