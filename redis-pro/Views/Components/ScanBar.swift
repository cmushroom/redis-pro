//
//  ScanBar.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/6/1.
//

import Foundation
import SwiftUI
import Logging
import ComposableArchitecture

struct ScanBar: View {
    @EnvironmentObject var globalContext:GlobalContext
    @ObservedObject var scanModel:ScanModel
    var action: (() throws -> Void)
    var totalLabel:String = "Total"
    var showTotal:Bool = true
    
    
    var store:StoreOf<PageStore>?
    let logger = Logger(label: "scan-bar")
    
    var body: some View {
        
        WithViewStore(store!) { viewStore in
            HStack(alignment:.center, spacing: 4) {
                if showTotal {
                    Text("\(totalLabel): \(scanModel.total)")
                        .font(MTheme.FONT_FOOTER)
                        .lineLimit(1)
                        .multilineTextAlignment(.trailing)
                }
                Picker("", selection: $scanModel.size) {
                    Text("10").tag(10)
                    Text("50").tag(50)
                    Text("100").tag(100)
                    Text("200").tag(200)
                }
                .onChange(of: scanModel.size, perform: { value in
                    logger.info("on scan size change: \(value)")
                    scanModel.reset()
                    doAction()
                })
                .frame(width: 65)
                
                HStack(alignment:.center, spacing: 2) {
                    MIcon(icon: "chevron.left", disabled: !scanModel.hasPrev || globalContext.loading, action: onPrevPageAction)
                    Text("\(scanModel.current)")
                        .font(MTheme.FONT_FOOTER)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .layoutPriority(1)
                    MIcon(icon: "chevron.right", disabled: !scanModel.hasNext || globalContext.loading, action: onNextPageAction)
                }
                .frame(minWidth: 60, idealWidth: 60)
            }
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
        scanModel.reset()
        try! action()
    }
}
