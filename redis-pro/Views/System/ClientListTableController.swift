//
//  ClientListTableController.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/6/25.
//

import Cocoa

class ClientListTableController: NSViewController {
    @objc dynamic var list: [[String:String]] = []
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet var arrayController: NSArrayController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        let tip:String = NSLocalizedString("REDIS_CLIENT_LIST_ID", tableName: nil, bundle: Bundle.main, value: "", comment: "")
        print("tips \(tip)")
        tableView.tableColumns[0].headerToolTip = tip
    }
    
    func setList(_ list:[[String:String]]) -> Void {
        self.list = list
        print("set list ...... \(list)")
    }
}
