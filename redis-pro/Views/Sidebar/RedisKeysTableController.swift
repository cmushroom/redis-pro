//
//  RedisKeysTableController.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/7/9.
//

import Foundation
import Cocoa
import Logging

class RedisKeysTableController: NSViewController {
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet var arrayController: NSArrayController!
    @IBAction func action(_ sender: NSTableView) {
        logger.info("table view click, row: \(sender.clickedRow)")
        self.action?(sender.clickedRow)
    }
    
    @objc dynamic var datasource: [RedisKeyModel] = []
    
    var deleteAction: ((_ index:Int) -> Void)?
    var renameAction: ((_ index:Int) -> Void)?
    var action: ((_ index:Int) -> Void)?
    
    let logger = Logger(label: "redis-keys-table-controller")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Rename", action: #selector(tableViewEditItemClicked(_:)), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Delete", action: #selector(tableViewDeleteItemClicked(_:)), keyEquivalent: ""))
        tableView.menu = menu
    }
    
    // 监听键盘删除事件
    override func keyDown(with event: NSEvent) {
        if event.specialKey == NSEvent.SpecialKey.delete {
            logger.info("on delete key down, delete index: \(tableView.selectedRow)")
            self.deleteAction?(tableView.selectedRow)
        }
       }
    
    func setDatasource(_ datasource:[RedisKeyModel]) -> Void {
        self.datasource = datasource
    }
    
    func setUp(action: ((_ index:Int) -> Void)?, deleteAction: @escaping (_ index:Int) -> Void, renameAction: @escaping (_ index:Int) -> Void) -> Void {
        self.deleteAction = deleteAction
        self.renameAction = renameAction
        self.action = action
    }
    
    @objc private func tableViewEditItemClicked(_ sender: AnyObject) {
        logger.info("context menu rename index: \(tableView.clickedRow)")
        self.renameAction?(tableView.clickedRow)
//        guard tableView.clickedRow >= 0 else { return }
    }
    
    @objc private func tableViewDeleteItemClicked(_ sender: AnyObject) {
        logger.info("context menu delete index: \(tableView.clickedRow)")
        self.deleteAction?(tableView.clickedRow)
    }
}
