//
//  NTable.swift
//  redis-pro
//
//  Created by chengpan on 2021/12/17.
//

import SwiftUI

struct NTable: NSViewRepresentable {
    var data = [RedisKeyModel("key1", type: "string"), RedisKeyModel("key2", type: "hash")]
    
    func makeNSView(context: Context) -> NSScrollView {
        let tableView = NSTableView()
        tableView.allowsMultipleSelection = true
        tableView.headerView = nil
        tableView.selectionHighlightStyle = .regular
        tableView.gridStyleMask = NSTableView.GridLineStyle.solidHorizontalGridLineMask
        let col = NSTableColumn()
        col.minWidth = 250
        tableView.addTableColumn(col)
        tableView.delegate = context.coordinator
        tableView.dataSource = context.coordinator
        tableView.usesAutomaticRowHeights = true
        let scrollView = NSScrollView()
        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        return scrollView
    }
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        print("Update table called")
        let tableView = (nsView.documentView as! NSTableView)
        context.coordinator.parent = self
        tableView.reloadData()
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    
    final class Coordinator: NSObject, NSTableViewDelegate, NSTableViewDataSource {
        var parent: NTable
        init(_ parent: NTable) {
            self.parent = parent
        }
        func numberOfRows(in tableView: NSTableView) -> Int {
            return parent.data.count
        }
        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
            let x = NSHostingView(rootView: Text("hello"))
            return x
        }
        func tableViewSelectionDidChange(_ notification: Notification) {
            print("tableViewSelectionDidChange \(notification)")
        }
    }

}

struct NTable_Previews: PreviewProvider {
    static var previews: some View {
        NTable()
    }
}
