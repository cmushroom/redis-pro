//
//  NTable.swift
//  redis-pro
//
//  Created by chengpan on 2021/12/17.
//

import SwiftUI
import Logging
import Cocoa

struct NTableView: NSViewControllerRepresentable {
    var columns:[NTableColumn] = [NTableColumn]()
    var datasource:[Any] = [Any]()
    
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    
    func makeNSViewController(context: Context) -> NSViewController {
        let controller = NTableController()
        controller.columns = columns
        controller.datasource = datasource
//        controller.setUp(action: self.onClick, deleteAction: self.deleteAction, renameAction: self.renameAction)
        controller.tableView.delegate = context.coordinator
        return controller
    }
    
    
    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {
        guard let controller = nsViewController as? NTableController else {return}
//        controller.setDatasource(datasource)
        controller.tableView.delegate = context.coordinator
        
//        controller.arrayController.setSelectionIndex(self.selectRowIndex)
    }
    
    
    class Coordinator: NSObject, NSTableViewDelegate {
        
        var table: NTableView
        
        let logger = Logger(label: "ntable-coordinator")
        
        
        init(_ table: NTableView) {
            self.table = table
        
        }
        
        func tableViewSelectionIsChanging(_ notification: Notification) {
            guard let tableView = notification.object as? NSTableView else {return}
//            guard self.table.datasource.count > 0 else {return}
            
            self.logger.info("redis key table Coordinator tableViewSelectionIsChanging, selectedRow: \(tableView.selectedRow)")
            
//            self.table.selectRowIndex = tableView.selectedRow
//            self.table.onChange?(self.table.selectRowIndex)
            
        }
        
        func tableViewSelectionDidChange(_ notification: Notification) {
            guard let tableView = notification.object as? NSTableView else {return}
//            guard self.table.datasource.count > 0 else {return}
            
            self.logger.info("redis key table Coordinator tableViewSelectionDidChang, selectedRow: \(tableView.selectedRow)")
        }

        
    }
}

class NTableController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    
    var columns:[NTableColumn] = [NTableColumn]()
    var datasource:[Any] = [Any]()
    
    var initialized = false
    let scrollView = NSScrollView()
    let tableView = NSTableView()
    
    
    override func loadView() {
        self.view = NSView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidLayout() {
        if !initialized {
            initialized = true
            setupView()
            setupTableView()
        }
    }
    
    /**
        NSLayoutConstraint(item: 视图,
         attribute: 约束属性,
         relatedBy: 约束关系,
         toItem: 参照视图,
         attribute: 参照属性,
         multiplier: 乘积,
         constant: 约束数值)
     */
    func setupView() {
        //使用Auto Layout的方式来布局
        self.view.translatesAutoresizingMaskIntoConstraints = false
////
//        self.view.addConstraint(NSLayoutConstraint(item: self.view, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 500))
    }
    
    func setupTableView() {
        self.view.addSubview(scrollView)
        self.scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addConstraint(NSLayoutConstraint(item: self.scrollView, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1.0, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: self.scrollView, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1.0, constant: 23))
        self.view.addConstraint(NSLayoutConstraint(item: self.scrollView, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .right, multiplier: 1.0, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: self.scrollView, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1.0, constant: 0))
        tableView.frame = scrollView.bounds
        tableView.delegate = self
        tableView.dataSource = self
        tableView.usesAlternatingRowBackgroundColors = true
//        tableView.headerView = nil
        scrollView.backgroundColor = NSColor.clear
        scrollView.drawsBackground = false
        scrollView.autohidesScrollers = true
//        scrollView.hasVerticalRuler = false
//        scrollView.automaticallyAdjustsContentInsets = false
        scrollView.contentInsets = NSEdgeInsets(top: 0, left: -40, bottom: 0, right: 0)
        scrollView.scrollerInsets = NSEdgeInsets(top: 0, left: -40, bottom: 0, right: 0)
//        scrollView.borderType = .noBorder
        
        tableView.style = .fullWidth
        tableView.backgroundColor = NSColor.clear
        tableView.appearance = NSAppearance(named: NSAppearance.Name.vibrantLight)
        
        tableView.columnAutoresizingStyle = .lastColumnOnlyAutoresizingStyle
        
        for column in columns {
            let col = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: column.key))
            col.width = column.width ?? column.type.width
            col.title = column.title
            tableView.addTableColumn(col)
        }

//
//        age2.maxWidth = 2000
//        age2.title = "Age"
////        age2.sizeToFit()
//        tableView.addTableColumn(age2)
    
        // 最后一列自适应
        tableView.sizeLastColumnToFit()
        
        scrollView.documentView = tableView
        
//        scrollView.addSubview(tableView)
        scrollView.hasHorizontalScroller = false
        scrollView.hasVerticalScroller = true
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return datasource.count
    }
    
    // 构建单元格
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let text = NSTextField()
        // 是否可以编辑
        text.isEditable = false

        text.stringValue = getColumnValue(row, column: tableColumn)
        let cell = NSTableCellView()
        cell.addSubview(text)
        text.drawsBackground = false
        text.isBordered = false
        text.translatesAutoresizingMaskIntoConstraints = false
        cell.addConstraint(NSLayoutConstraint(item: text, attribute: .centerY, relatedBy: .equal, toItem: cell, attribute: .centerY, multiplier: 1, constant: 0))
        cell.addConstraint(NSLayoutConstraint(item: text, attribute: .left, relatedBy: .equal, toItem: cell, attribute: .left, multiplier: 1, constant: 5))
        cell.addConstraint(NSLayoutConstraint(item: text, attribute: .right, relatedBy: .equal, toItem: cell, attribute: .right, multiplier: 1, constant: 4))
        return cell
    }
    
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        let rowView = NSTableRowView()
        //  是否突出显示
        rowView.isEmphasized = false
        return rowView
    }
    
    private func getColumnValue(_ row:Int, column:NSTableColumn?) -> String {
        let rowAnyObj = datasource[row]
        let key = column?.identifier.rawValue ?? "_"
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
    
    
}

struct NTable_Previews: PreviewProvider {
    static var columns:[NTableColumn] = [NTableColumn(title: "name", key: "name"),  NTableColumn(title: "age", key: "age", width: 100)]
    static var datasource:[Any] = [["name":"tom", "age":"10"], ["name": "jimi", "age":"12"]]
    static var previews: some View {
        HStack {
            NTableView(columns: columns, datasource: datasource)
                .preferredColorScheme(.light)
        }
        .frame(width: 700, height: 600, alignment: .leading)
        .background(Color.gray)
    }
}
