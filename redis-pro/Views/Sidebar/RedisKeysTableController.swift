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
    
    @objc dynamic var datasource: [NSRedisKeyModel] = []
    
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
    
    func setDatasource(_ datasource:[NSRedisKeyModel]) -> Void {
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


class RedisKeyTableRow:NSObject, Identifiable  {
    @objc var no:Int
    @objc var type:String
    @objc var key:String
    
    @objc var typeColor: NSColor {
        switch type {
        case RedisKeyTypeEnum.STRING.rawValue:
            return NSColor.systemBlue
        case RedisKeyTypeEnum.HASH.rawValue:
            return NSColor.systemPink
        case RedisKeyTypeEnum.LIST.rawValue:
            return NSColor.systemOrange
        case RedisKeyTypeEnum.SET.rawValue:
            return NSColor.systemGreen
        case RedisKeyTypeEnum.ZSET.rawValue:
            return NSColor.systemTeal
        default:
            return NSColor.systemBrown
        }
    }
    
    init(no:Int, type:String, key:String) {
        self.no = no
        self.type = type
        self.key = key
    }
}
