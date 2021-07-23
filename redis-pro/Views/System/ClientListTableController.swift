//
//  ClientListTableController.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/6/25.
//

import Cocoa

class ClientListTableController: NSViewController {
    @objc dynamic var datasource: [ClientModel] = []
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet var arrayController: NSArrayController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 提示
        for column in tableView.tableColumns {
            let tip:String = NSLocalizedString("REDIS_CLIENT_LIST_\(column.identifier.rawValue)".uppercased(), tableName: nil, bundle: Bundle.main, value: "", comment: "")
            column.title = column.title + " ?"
//            column.headerCell = MyHeaderCell()
            column.headerToolTip = tip
        }
    }
    
    func setDatasource(_ datasource:[ClientModel]) -> Void {
        self.datasource = datasource
    }
}

class MyHeaderCell: NSTableHeaderCell {
    override func drawInterior(withFrame cellFrame: NSRect, in controlView: NSView) {
//        controlView.addSubview(NSImage())
        super.drawInterior(withFrame: cellFrame, in: controlView)
    }
}
