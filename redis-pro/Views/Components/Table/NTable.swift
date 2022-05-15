//
//  NTable.swift
//  redis-pro
//
//  Created by chengpan on 2021/12/17.
//

import SwiftUI
import Logging
import Cocoa
import Combine
import ComposableArchitecture

struct NTableView: NSViewControllerRepresentable {
//    var columns:[NTableColumn] = [NTableColumn]()
//    @Binding var datasource:[AnyHashable]
//    @Binding var selectIndex:Int
//    var onChange: ((Int, AnyHashable) -> Void)?
//    var onDelete: ((Int, AnyHashable) -> Void)?
//    var onDouble: ((Int, AnyHashable) -> Void)?
    
    let store: Store<TableState, TableAction>
    
    let logger = Logger(label: "ntable")
    
    
    func makeCoordinator() -> Coordinator {
        logger.debug("init ntable coordinator...")
        return Coordinator(self)
    }
    
    
    func makeNSViewController(context: Context) -> NSViewController {
        let controller = NTableController(store)
//        controller.onChangeAction = self.onChange
//        controller.onDeleteAction = self.onDelete
//        controller.onDoubleAction = self.onDouble
//        controller.columns = columns
        
//        controller.tableView.delegate = context.coordinator
        
//        controller.datasource = datasource
//        controller.setUp(action: self.onClick, deleteAction: self.deleteAction, renameAction: self.renameAction)
//        controller.tableView.delegate = context.coordinator
//        controller.tableView.dataSource = context.coordinator
        
        logger.debug("ntable make nsview controller....")
        return controller
    }
    
    
    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {
//        guard let controller = nsViewController as? NTableController else {return}
//        controller.setDatasource(datasource)
//        controller.tableView.delegate = context.coordinator
//        controller.tableView.dataSource = context.coordinator
        
        logger.debug("ntable update nsview controller")
        
        //TODO 刷新次数太多，考虑优化
//        controller.refresh(self.datasource)
        
//        if self.selectIndex != controller.arrayController.selectionIndex {
//            controller.arrayController.setSelectionIndex(self.selectIndex)
//        }
        
//        DispatchQueue.main.async {
//            controller.arrayController.setSelectionIndex(self.selectIndex)
//        }
    }
    
    class Coordinator: NSObject, NSTableViewDelegate, NSTableViewDataSource {
        
        var table: NTableView
        
        let logger = Logger(label: "table-coordinator")
        
        
        init(_ table: NTableView) {
            self.table = table
        }
    }
}

class NTableController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    
//    var columns:[NTableColumn] = [NTableColumn]()
    @objc dynamic var datasource:[AnyHashable] = []
    var arrayController = NSArrayController()
    var initialized = false
    let scrollView = NSScrollView()
    let tableView = NSTableView()
    
    let viewStore: ViewStore<TableState, TableAction>
    var cancellables: Set<AnyCancellable> = []
    
    var observation: NSKeyValueObservation?
    
    let logger = Logger(label: "table-view-controller")
    
    init(_ store: Store<TableState, TableAction>) {
        logger.info("table controller init...")
        self.viewStore = ViewStore(store)
        
        // init table data
        self.datasource = self.viewStore.datasource
        self.arrayController.setSelectionIndex(self.viewStore.selectIndex)
        
        super.init(nibName: nil, bundle: nil)
        
        // set table dark mode
        self.view.appearance = NSApp.appearance
        self.tableView.appearance = NSApp.appearance
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        self.view = NSView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if initialized {
            return
        }
        initialized = true
        
        // listen app color scheme
        observation = NSApp.observe(\.effectiveAppearance) { (app, _) in
               app.effectiveAppearance.performAsCurrentDrawingAppearance {
                   // Invoke your non-view code that needs to be aware of the
                   // change in appearance.
                   self.logger.info("app color scheme change, update table view ...")
                   self.view.appearance = NSApp.appearance
                   self.tableView.appearance = NSApp.appearance
               }
           }
            
        tableView.allowsEmptySelection = false
        
        arrayController.bind(.contentArray, to: self, withKeyPath: "datasource", options: nil)
        
        tableView.bind(.content, to: arrayController, withKeyPath: "arrangedObjects", options: nil)
        tableView.bind(.selectionIndexes, to: arrayController, withKeyPath:"selectionIndexes", options: nil)
    
        setupView()
        setupTableView()
        
        // 监听
        self.viewStore.publisher.defaultSelectIndex
            .sink(receiveValue: {
                self.logger.debug("table store select index publisher, index: \($0)")
                let selectIndex = min($0, self.viewStore.datasource.count - 1)
                self.arrayController.setSelectionIndex(selectIndex)
            })
            .store(in: &self.cancellables)
        
        self.viewStore.publisher.datasource
            .sink(receiveValue: {
                self.logger.debug("table store data source publisher, data source length: \($0.count)")
                let selectIndex = min(self.viewStore.selectIndex, $0.count - 1)
                
                self.datasource = $0
                self.arrayController.setSelectionIndex(selectIndex)
            })
            .store(in: &self.cancellables)
        
        // 初始化右键菜单
        if !viewStore.contextMenus.isEmpty {
            let menu = NSMenu()
            viewStore.contextMenus.forEach { item in
                menu.addItem(NSMenuItem(title: item, action: #selector(contextMenuAction(_:)), keyEquivalent: ""))
            }
            
            tableView.menu = menu
        }
    }
    
//    override func viewDidLayout() {
//        if !initialized {
//            initialized = true
//        }
//    }
    
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
    }
    
    func setupTableView() {
        self.view.addSubview(scrollView)
        self.scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addConstraint(NSLayoutConstraint(item: self.scrollView, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1.0, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: self.scrollView, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1.0, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: self.scrollView, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .right, multiplier: 1.0, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: self.scrollView, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1.0, constant: 0))
        tableView.frame = scrollView.bounds
        tableView.delegate = self
        
//        tableView.dataSource = self
        tableView.usesAlternatingRowBackgroundColors = true
//        tableView.headerView = nil
        scrollView.backgroundColor = NSColor.clear
        scrollView.drawsBackground = false
        scrollView.autohidesScrollers = true
        scrollView.contentInsets = NSEdgeInsets(top: 0, left: -40, bottom: 0, right: 0)
        scrollView.scrollerInsets = NSEdgeInsets(top: 0, left: -40, bottom: 0, right: 0)
        
        tableView.style = .fullWidth
        tableView.backgroundColor = NSColor.clear
        tableView.appearance = NSAppearance(named: NSAppearance.Name.vibrantLight)
        
        tableView.columnAutoresizingStyle = .lastColumnOnlyAutoresizingStyle
        
        tableView.doubleAction = #selector(onDoubleAction(_:))
        
        for column in viewStore.columns {
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
    
   
    
    // 构建单元格
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let tableColumn = tableColumn else {
            return nil
        }

        
        guard let column = self.viewStore.columns.filter({ $0.key == tableColumn.identifier.rawValue}).first else { return nil }
        
        var tableCellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(column.key), owner: self) as? TableCellView
        if tableCellView == nil {
            tableCellView = TableCellView(tableView, tableColumn: tableColumn, column: column, row: row)
        }
        
        return tableCellView
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        guard let tableView = notification.object as? NSTableView else {return}
        
        let selectIndex = tableView.selectedRow
        self.logger.info("table coordinator selection did change, selectedRow: \(selectIndex)")
        
//        guard self.datasource.count > selectIndex && selectIndex > -1 else {return}
        
//        self.selectIndex = tableView.selectedRow
//        self.onChangeAction?(tableView.selectedRow, self.datasource[selectIndex])
        
        self.viewStore.send(.selectionChange(selectIndex))
    }
    
    // 监听键盘删除事件
    override func keyDown(with event: NSEvent) {
        if event.specialKey == NSEvent.SpecialKey.delete {
            logger.info("on delete key down, delete index: \(tableView.selectedRow)")
            let selectIndex = tableView.selectedRow
            
            if selectIndex > -1 {
//                self.onDeleteAction?(selectIndex, self.datasource[selectIndex])
                self.viewStore.send(.delete(selectIndex))
            }
        }
    }
    
    
    // double click action
    @objc private func onDoubleAction(_ sender: AnyObject) {
        logger.info("table view on double click action, row: \(tableView.clickedRow)")
        let selectIndex = tableView.clickedRow
        guard selectIndex > -1 && selectIndex < self.datasource.count else {
            return
        }
        
        self.viewStore.send(.double(selectIndex))
    }
    
    
    // context menu
    @objc private func contextMenuAction(_ sender: AnyObject) {
        guard let menuItem = sender as? NSMenuItem else {
            return
        }
        
        let index = tableView.clickedRow
        if index < 0 {
            return
        }
        logger.info("context menu action, index: \(index)")
        self.viewStore.send(.contextMenu(menuItem.title, index))
    }
}

//struct NTable_Previews: PreviewProvider {
//    static var columns:[NTableColumn] = [NTableColumn(type: .IMAGE, title: "icon", key: "name", width: 20),  NTableColumn(title: "name", key: "name", width: 100)]
//    @State private static var datasource:[Any] = [RedisModel(name: "hello-test"), RedisModel(name: "hello-dev")]
//    @State static var index = 1
//    static var previews: some View {
//        VStack {
//            NTableView(columns: columns, datasource: $datasource, selectIndex: $index)
//                .preferredColorScheme(.light)
//
//            Text("\(index), \(datasource.count)")
//            Button("add", action: {
//                self.index += 1
//                datasource.append(RedisModel(name: "helllolsfas"))
//            })
//        }
//        .frame(width: 700, height: 600, alignment: .leading)
//        .background(Color.gray)
//    }
//}
