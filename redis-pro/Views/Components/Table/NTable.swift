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
    @Binding var datasource:[Any]
    @Binding var selectIndex:Int
    var onChange: ((Int) -> Void)?
    var onDelete: ((Int) -> Void)?
    var onDouble: ((Int) -> Void)?
    
    let logger = Logger(label: "ntable")
    
    
    func makeCoordinator() -> Coordinator {
        logger.info("init ntable coordinator...")
        return Coordinator(self)
    }
    
    
    func makeNSViewController(context: Context) -> NSViewController {
        let controller = NTableController()
        controller.onChangeAction = self.onChange
        controller.onDeleteAction = self.onDelete
        controller.onDoubleAction = self.onDouble
        controller.columns = columns
//        controller.datasource = datasource
//        controller.setUp(action: self.onClick, deleteAction: self.deleteAction, renameAction: self.renameAction)
//        controller.tableView.delegate = context.coordinator
//        controller.tableView.dataSource = context.coordinator
        return controller
    }
    
    
    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {
        guard let controller = nsViewController as? NTableController else {return}
//        controller.setDatasource(datasource)
        controller.tableView.delegate = context.coordinator
//        controller.tableView.dataSource = context.coordinator
        
        controller.refresh(self.datasource)
        
        DispatchQueue.main.async {
            controller.arrayController.setSelectionIndex(self.selectIndex)
        }
        logger.info("ntable update nsview controller, datasource count: \(self.datasource.count), \(controller.arrayController.selectionIndexes)")
    }
    
    func onConfirmDelete(index:Int) {
        guard let deleteAction = onDelete else  {
            return
        }
        MAlert.confirm("", message: "", primaryButton: "Delete", secondButton: "Cancel", primaryAction: {
            deleteAction(index)
        }, style: .warning)
    }
    
    
    class Coordinator: NSObject, NSTableViewDelegate, NSTableViewDataSource {
        
        var table: NTableView
        
        let logger = Logger(label: "table-coordinator")
        
        
        init(_ table: NTableView) {
            self.table = table
        }
        
        // 构建单元格
        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
            guard let tableColumn = tableColumn else {
                return nil
            }

            guard let column = self.table.columns.filter({ $0.key == tableColumn.identifier.rawValue}).first else { return nil }
            
            var tableCellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(column.key), owner: self) as? TableCellView
            if tableCellView == nil {
                tableCellView = TableCellView(tableView, tableColumn: tableColumn, column: column, row: row)
            }
            
            return tableCellView
        }
        
        func tableViewSelectionIsChanging(_ notification: Notification) {
            guard let tableView = notification.object as? NSTableView else {return}
//            guard self.table.datasource.count > 0 else {return}
            
            self.logger.info("table coordinator selection changing, selectedRow: \(tableView.selectedRow)")
            
//            self.table.selectRowIndex = tableView.selectedRow
//            self.table.onChange?(self.table.selectRowIndex)
        }
        
        func tableViewSelectionDidChange(_ notification: Notification) {
            guard let tableView = notification.object as? NSTableView else {return}
//            guard self.table.datasource.count > 0 else {return}
            
            self.logger.info("table coordinator selection change, selectedRow: \(tableView.selectedRow)")
            self.table.onChange?(tableView.selectedRow)
        }
        
    }
}

class NTableController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    
    var columns:[NTableColumn] = [NTableColumn]()
    @objc dynamic var datasource:[Any] = [Any]()
    var arrayController = NSArrayController()
    var initialized = false
    let scrollView = NSScrollView()
    let tableView = NSTableView()
    
    var onDeleteAction: ((Int) -> Void)?
    var onDoubleAction: ((Int) -> Void)?
    var onChangeAction: ((Int) -> Void)?
    
    let logger = Logger(label: "table-view-controller")
    
    func refresh(_ datasource: [Any]) {
        self.datasource = datasource
        logger.info("table view controller refresh, data length: \((arrayController.arrangedObjects as! Array<Any>).count)")
    }
    
    override func loadView() {
        self.view = NSView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidLayout() {
        if !initialized {
            initialized = true
            arrayController.bind(.contentArray, to: self, withKeyPath: "datasource", options: nil)
//            arrayController.bind(.selectionIndexes, to: self, withKeyPath: "selectIndex", options: nil)
            
            tableView.bind(.content, to: arrayController, withKeyPath: "arrangedObjects", options: nil)
            tableView.bind(.selectionIndexes, to: arrayController, withKeyPath:"selectionIndexes", options: nil)
//            tableView.bind(.selectedIndex, to: arrayController, withKeyPath:"selectedIndex", options: nil)
//            tableView.bind(NSSortDescriptorsBinding, toObject: arrayController, withKeyPath: "sortDescriptors", options: nil)
            
            tableView.allowsEmptySelection = false
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
        self.view.addConstraint(NSLayoutConstraint(item: self.scrollView, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1.0, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: self.scrollView, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .right, multiplier: 1.0, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: self.scrollView, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1.0, constant: 0))
        tableView.frame = scrollView.bounds
//        tableView.delegate = self
//        tableView.dataSource = self
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
        
        tableView.doubleAction = #selector(onDoubleAction(_:))
        
        for column in columns {
            let col = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: column.key))
            col.width = column.width ?? column.type.width
            col.title = column.title
            tableView.addTableColumn(col)
        }
    
        // 最后一列自适应
        tableView.sizeLastColumnToFit()
        
        scrollView.documentView = tableView
        
//        scrollView.addSubview(tableView)
        scrollView.hasHorizontalScroller = false
        scrollView.hasVerticalScroller = true
    }
    
    // 使用array controller, 不需要此方法
//    func numberOfRows(in tableView: NSTableView) -> Int {
//        return self.datasource.count
//    }
    
    // 构建单元格
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let tableColumn = tableColumn else {
            return nil
        }

        guard let column = columns.filter({ $0.key == tableColumn.identifier.rawValue}).first else { return nil }
        
        var tableCellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(column.key), owner: self) as? TableCellView
        if tableCellView == nil {
            tableCellView = TableCellView(tableView, tableColumn: tableColumn, column: column, row: row)
        }
        
        return tableCellView
    }
    
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        let rowView = NSTableRowView()
        //  是否突出显示
        rowView.isEmphasized = false
        return rowView
    }
    
    // on change
    func tableViewSelectionDidChange(_ notification: Notification) {
        guard let tableView = notification.object as? NSTableView else {return}
        self.onChangeAction?(tableView.selectedRow)
        self.logger.info("table view controller selection change, selectedRow: \(tableView.selectedRow)")
    }
    
    // 监听键盘删除事件
    override func keyDown(with event: NSEvent) {
        if event.specialKey == NSEvent.SpecialKey.delete {
            logger.info("on delete key down, delete index: \(tableView.selectedRow)")
            self.onDeleteAction?(tableView.clickedRow)
        }
    }
    
    
    // double click action
    @objc private func onDoubleAction(_ sender: AnyObject) {
        logger.info("table view on double click action, row: \(tableView.clickedRow)")
        self.onDoubleAction?(tableView.clickedRow)
    }
}

struct NTable_Previews: PreviewProvider {
    static var columns:[NTableColumn] = [NTableColumn(type: .IMAGE, title: "icon", key: "name", width: 20),  NTableColumn(title: "name", key: "name", width: 100)]
    @State private static var datasource:[Any] = [RedisModel(name: "hello-test"), RedisModel(name: "hello-dev")]
    @State static var index = 1
    static var previews: some View {
        VStack {
            NTableView(columns: columns, datasource: $datasource, selectIndex: $index)
                .preferredColorScheme(.light)
            
            Text("\(index), \(datasource.count)")
            Button("add", action: {
                self.index += 1
                datasource.append(RedisModel(name: "helllolsfas"))
            })
        }
        .frame(width: 700, height: 600, alignment: .leading)
        .background(Color.gray)
    }
}
