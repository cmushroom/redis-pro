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
    }
    
    
}
