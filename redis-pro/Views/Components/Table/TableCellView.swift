//
//  TableCell.swift
//  redis-pro
//
//  Created by chengpan on 2022/4/4.
//

import Foundation
import Cocoa
import Logging

class TableCellView: NSTableCellView {

    var aTextField: NSTextField?
    
    let logger = Logger(label: "table-cell")

    init(_ tableView: NSTableView, tableColumn: NSTableColumn,column: NTableColumn, row:Int) {
        let identifier = tableColumn.identifier
        let key = column.key
        logger.info("table cell init, column: \(identifier.rawValue), row: \(row)")
        let frameRect = NSRect(x: 0, y: 0, width: tableColumn.width, height: tableView.rowHeight)
        super.init(frame: frameRect)
        self.identifier = identifier
        
        let textField = NSTextField()
        // 是否可以编辑
        textField.isEditable = false
        textField.drawsBackground = false
        textField.isBordered = false
        
        textField.bind(.value, to: self, withKeyPath: "objectValue.\(key)", options: nil)
//        textField.stringValue = getColumnValue(column, row: row, rowAnyObj: rowObj)
        
        
        let stackView = NSStackView()
        stackView.orientation = .horizontal
        stackView.spacing = 4
        
        if (column.icon != nil) {
            let iconFrame = NSRect(x: 0, y: 0, width: 20, height: 20)
            let imageView = NSImageView(frame: iconFrame)
            imageView.image = column.icon?.image
            imageView.imageScaling = .scaleNone
            
            stackView.addView(imageView, in: .leading)
        }
        
//        stackView.alignment = .
//        stackView.wantsLayer = true
//        stackView.layer?.backgroundColor = NSColor.blue.cgColor
        stackView.addView(textField, in: .leading)
        
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(stackView)

        NSLayoutConstraint(item: stackView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: stackView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: stackView, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: stackView, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: 0).isActive = true
        
    }
    
    private func getColumnValue(_ column:NTableColumn, row:Int, rowAnyObj: Any) -> String {
        let key = column.key
        var value:Any?
        if rowAnyObj is Dictionary<String, Any> {
            let rowObj = rowAnyObj as! Dictionary<String, Any>
            value = rowObj[key]
        } else if rowAnyObj is NSObject {
            let rowObj = rowAnyObj as! NSObject
            value = rowObj.value(forKey: key)
        }
        
        guard let value = value else {
            return "-"
        }
        
        return "\(value)"
    }
    

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
