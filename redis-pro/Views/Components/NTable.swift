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
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    
    func makeNSViewController(context: Context) -> NSViewController {
        let controller = NTableController()
//        controller.setUp(action: self.onClick, deleteAction: self.deleteAction, renameAction: self.renameAction)
        return controller
    }
    
    
    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {
        guard let controller = nsViewController as? NTableController else {return}
//        controller.setDatasource(datasource)
//        controller.tableView?.delegate = context.coordinator
        
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
    
    func setupView() {
        self.view.translatesAutoresizingMaskIntoConstraints = false
        self.view.addConstraint(NSLayoutConstraint(item: self.view, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 400))
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
        tableView.backgroundColor = NSColor.clear
        tableView.appearance = NSAppearance(named: NSAppearance.Name.vibrantLight)
        
        tableView.columnAutoresizingStyle = .lastColumnOnlyAutoresizingStyle

        let col = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: "col"))
        col.minWidth = 200
        col.title = "Name"
        tableView.addTableColumn(col)
        
        let age = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: "age"))
        age.minWidth = 200
        age.title = "Age"
        age.isEditable = false
        tableView.addTableColumn(age)
    
        
        scrollView.documentView = tableView
        scrollView.hasHorizontalScroller = false
        scrollView.hasVerticalScroller = true
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return 22
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let text = NSTextField()
        let i = tableColumn?.identifier.rawValue ?? "null"
        text.stringValue = "Hello World-\(i)"
        let cell = NSTableCellView()
        cell.addSubview(text)
        text.drawsBackground = false
        text.isBordered = false
        text.translatesAutoresizingMaskIntoConstraints = false
        cell.addConstraint(NSLayoutConstraint(item: text, attribute: .centerY, relatedBy: .equal, toItem: cell, attribute: .centerY, multiplier: 1, constant: 0))
        cell.addConstraint(NSLayoutConstraint(item: text, attribute: .left, relatedBy: .equal, toItem: cell, attribute: .left, multiplier: 1, constant: 13))
        cell.addConstraint(NSLayoutConstraint(item: text, attribute: .right, relatedBy: .equal, toItem: cell, attribute: .right, multiplier: 1, constant: -13))
        return cell
    }
    
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        let rowView = NSTableRowView()
        rowView.isEmphasized = false
        return rowView
    }
    
}

struct NTable_Previews: PreviewProvider {
    static var previews: some View {
        NTableView()
            .preferredColorScheme(.light)
    }
}
