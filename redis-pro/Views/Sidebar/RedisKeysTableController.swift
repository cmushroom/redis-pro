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
    
    @objc dynamic var datasource: [RedisKeyModel] = []
    
    var deleteAction: (_ index:Int) -> Void = {_ in }
    var renameAction: (_ index:Int) -> Void = {_ in }
    
    let logger = Logger(label: "redis-keys-table-controller")
    
    func setUp(deleteAction: @escaping (_ index:Int) -> Void, renameAction: @escaping (_ index:Int) -> Void) -> Void {
        self.deleteAction = deleteAction
        self.renameAction = renameAction
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Rename", action: #selector(tableViewRenameItemClicked(_:)), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Delete", action: #selector(tableViewDeleteItemClicked(_:)), keyEquivalent: ""))
        tableView.menu = menu
        
    }
    
    func setDatasource(_ datasource:[RedisKeyModel]) -> Void {
        self.datasource = datasource
    }
    
    @objc private func tableViewRenameItemClicked(_ sender: AnyObject) {
        logger.info("context menu rename index: \(tableView.clickedRow)")
        self.renameAction(tableView.clickedRow)
//        guard tableView.clickedRow >= 0 else { return }
    }
    
    @objc private func tableViewDeleteItemClicked(_ sender: AnyObject) {
        logger.info("context menu delete index: \(tableView.clickedRow)")
        self.deleteAction(tableView.clickedRow)
//        guard tableView.clickedRow >= 0 else { return }
        //
        //        items.remove(at: tableView.clickedRow)
        //
        //        tableView.reloadData()
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
