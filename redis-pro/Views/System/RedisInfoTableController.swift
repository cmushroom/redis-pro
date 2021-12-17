//
//  RedisInfoTableController.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/7/19.
//

import Foundation
import Cocoa
import Logging
import SwiftUI

class RedisInfoTableController: NSViewController {
    @objc dynamic var datasource: [RedisInfoItemModel] = []
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet var arrayController: NSArrayController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        tableView.tableColumns.forEach({column in
//            let cell = column.dataCell as! NSCell
//            cell.controlSize = .large
//            cell.font = NSFont.systemFont(ofSize: 14)
//            //            return cell
//        })
    }
        
    func setDatasource(_ datasource:[RedisInfoItemModel]) -> Void {
        self.datasource = datasource
    }
}




struct RedisInfoTable: NSViewControllerRepresentable {
    @Binding var datasource: [RedisInfoItemModel]
    @Binding var selectRowIndex:Int?
    
    let logger = Logger(label: "redis-info-table")
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    
    func makeNSViewController(context: Context) -> NSViewController {
        let controller = RedisInfoTableController()
        
        return controller
    }
    
    
    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {
            
        guard let controller = nsViewController as? RedisInfoTableController else {return}
        controller.setDatasource(datasource)
        controller.tableView?.delegate = context.coordinator
        
        controller.arrayController.setSelectionIndex(selectRowIndex ?? -1)
//        controller.tableView.scrollRowToVisible(selectRowIndex)
    }
    
    class Coordinator: NSObject, NSTableViewDelegate {
        
        var table: RedisInfoTable
        
        let logger = Logger(label: "redis-info-table-coordinator")
        
        
        init(_ table: RedisInfoTable) {
            self.table = table
        }
        
        func tableViewSelectionIsChanging(_ notification: Notification) {
            guard let tableView = notification.object as? NSTableView else {return}
            guard self.table.datasource.count > 0 else {return}
            
            self.table.selectRowIndex = tableView.selectedRow == -1 ? nil : tableView.selectedRow

        }
        func tableView(_ tableView: NSTableView,
                willDisplayCell cell: Any,
                            for tableColumn: NSTableColumn?,
                       row: Int) {
            print("celll      \(cell)")
        }
//        func tableView(_ tableView: NSTableView,
//                        viewFor tableColumn: NSTableColumn?,
//                       row: Int) -> NSView? {
//            print("...................... \(tableColumn)")
//            let view = NSTextFieldCell()
//            let v = NSTableCellView()
//            v.textField?.stringValue = "hello"
//            return v
//        }
//        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
//            print("...................... \(tableColumn)")
//            // Assuming that you have set the cell view's Identifier in Interface Builder
//            tableColumn?.dataCell
//            let cell = NSTableCellView()
//
//            cell.textField?.stringValue = "helllo"
//
//            cell.textField?.font = NSFont.systemFont(ofSize: 14)
//
//            return cell
//        }
//        func tableView(_ tableView: NSTableView,
//                        viewFor tableColumn: NSTableColumn?,
//                       row: Int) -> NSView? {
//            let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "mcell"), owner: self) as!NSTableCellView
//            cell.textField?.font = NSFont.systemFont(ofSize: 14)
//            return cell
//        }
    }
    
    
}
