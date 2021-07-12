//
//  RedisListTableController.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/7/12.
//

import Foundation
import Cocoa
import SwiftUI
import Logging

class RedisListTableController: NSViewController {
    let logger = Logger(label: "redis-list-table-controller")
    @objc var doubleAction: () -> Void = {}
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet var arrayController: NSArrayController!
    
    @IBAction func doubleAction(_ sender: Any) {
        if self.tableView.selectedRow < 0 {
            return
        }
        logger.info("redis list table double action")
        self.doubleAction()
    }
    
    @objc dynamic var datasource: [RedisModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func setUp(doubleAction: @escaping () -> Void) -> Void {
        self.doubleAction = doubleAction
    }
    
    func setDatasource(_ datasource:[RedisModel]) -> Void {
        self.datasource = datasource
    }
}


struct RedisListTable: NSViewControllerRepresentable {
    @Binding var datasource: [RedisModel]
    @Binding var selectRowIndex:Int?
    
    var doubleAction: () -> Void = {}
    
    let logger = Logger(label: "redis-list-table")
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    
    func makeNSViewController(context: Context) -> NSViewController {
        let controller = RedisListTableController()
        controller.setUp(doubleAction: self.doubleAction)
        return controller
    }
    
    
    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {
        guard let controller = nsViewController as? RedisListTableController else {return}
        controller.setDatasource(datasource)
        controller.tableView?.delegate = context.coordinator
        
        controller.arrayController.setSelectionIndex(self.selectRowIndex ?? -1)
    }
    
    
    class Coordinator: NSObject, NSTableViewDelegate {
        
        var table: RedisListTable
        
        let logger = Logger(label: "client-list-table-coordinator")
        
        
        init(_ table: RedisListTable) {
            self.table = table
        
        }
        
        func tableViewSelectionIsChanging(_ notification: Notification) {
            guard let tableView = notification.object as? NSTableView else {return}
            guard self.table.datasource.count > 0 else {return}
            
            self.logger.info("redis list table Coordinator tableViewSelectionIsChanging, selectedRow: \(tableView.selectedRow)")
            
            self.table.selectRowIndex = tableView.selectedRow == -1 ? nil : tableView.selectedRow
            
        }
        
    }
    
}
