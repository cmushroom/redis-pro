//
//  SlowLogTableController.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/7/14.
//

import Foundation
import Cocoa
import Logging
import SwiftUI

class SlowLogTableController: NSViewController {
    @objc dynamic var datasource: [Any] = []
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet var arrayController: NSArrayController!
    
    override func viewWillAppear() {
     
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 提示
        for column in tableView.tableColumns {
            let tip:String = NSLocalizedString("REDIS_SLOW_LOG_\(column.identifier.rawValue)".uppercased(), tableName: nil, bundle: Bundle.main, value: "", comment: "")
            column.title = column.title + "􀁜"
            column.headerToolTip = tip
        }
        
    }
        
    func setDatasource(_ datasource:[Any]) -> Void {
        self.datasource = datasource
    }
}

struct SlowLogTable: NSViewControllerRepresentable {
    @Binding var datasource: [Any]
    @Binding var selectRowIndex:Int?
    
    let logger = Logger(label: "slow-log-table")
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    
    func makeNSViewController(context: Context) -> NSViewController {
        let controller = SlowLogTableController()
        
        return controller
    }
    
    
    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {
            
        guard let controller = nsViewController as? SlowLogTableController else {return}
        controller.setDatasource(datasource)
        controller.tableView?.delegate = context.coordinator
        
        controller.arrayController.setSelectionIndex(selectRowIndex ?? -1)
//        controller.tableView.scrollRowToVisible(selectRowIndex)
    }
    
    class Coordinator: NSObject, NSTableViewDelegate {
        
        var table: SlowLogTable
        
        let logger = Logger(label: "slow-log-table-coordinator")
        
        
        init(_ table: SlowLogTable) {
            self.table = table
        
        }
        
        func tableViewSelectionIsChanging(_ notification: Notification) {
            guard let tableView = notification.object as? NSTableView else {return}
            guard self.table.datasource.count > 0 else {return}
            
            self.table.selectRowIndex = tableView.selectedRow == -1 ? nil : tableView.selectedRow

        }
    }
    
    
}
