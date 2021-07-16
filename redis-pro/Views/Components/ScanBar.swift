//
//  ScanBar.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/6/1.
//

import Foundation
import SwiftUI
import Logging
import PromiseKit

struct ScanBar: View {
    @EnvironmentObject var globalContext:GlobalContext
    @ObservedObject var scanModel:ScanModel
    var action: (() throws -> Void)
    var totalLabel:String = "Total"
    
    let logger = Logger(label: "scan-bar")
    
    var body: some View {
        HStack(alignment:.center, spacing: 4) {
            Spacer()
            Text("\(totalLabel): \(scanModel.total)")
                .font(.footnote)
                .lineLimit(1)
                .multilineTextAlignment(.trailing)
            
            Picker("", selection: $scanModel.size) {
                Text("10").tag(10)
                Text("50").tag(50)
                Text("100").tag(100)
                Text("200").tag(200)
            }
            .help(Helps.SCAN_COUNT)
            .onChange(of: scanModel.size, perform: { value in
                logger.info("on scan size change: \(value)")
                scanModel.resetHead()
                doAction()
            })
            .font(.system(size: 8))
            .frame(width: 65)
            
            HStack(alignment:.center) {
                MIcon(icon: "chevron.left", disabled: !scanModel.hasPrev || globalContext.loading, action: onPrevPageAction)
                Text("\(scanModel.current)")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                MIcon(icon: "chevron.right", disabled: !scanModel.hasNext || globalContext.loading, action: onNextPageAction)
            }
            .layoutPriority(1)
        }
    }
    
    func onNextPageAction() -> Void {
        self.scanModel.nextPage()
        try! action()
    }
    
    func onPrevPageAction() -> Void {
        scanModel.prevPage()
        try! action()
    }
    
    func doAction() -> Void {
        logger.info("scan bar on change action, scanModel: \(scanModel)")
        scanModel.resetHead()
        try! action()
    }
}
