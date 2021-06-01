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

struct ScanBar<T:Thenable>: View {
    @EnvironmentObject var globalContext:GlobalContext
    @ObservedObject var scanModel:ScanModel
    var action: (() -> T)?
    
    let logger = Logger(label: "scan-bar")
    
    var body: some View {
        HStack(alignment:.center, spacing: 4) {
            Spacer()
            Text("Total: \(scanModel.total)")
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
            .font(.footnote)
            .frame(width: 65)
            
            HStack(alignment:.center) {
                MIcon(icon: "chevron.left", disabled: !scanModel.hasPrev || globalContext.loading, action: onPrevPageAction)
//                Text("\(page.current)/\(page.totalPage)")
//                    .font(.footnote)
//                    .multilineTextAlignment(.center)
//                    .lineLimit(1)
                MIcon(icon: "chevron.right", disabled: !scanModel.hasNext || globalContext.loading, action: onNextPageAction)
            }
            .layoutPriority(1)
        }
    }
    
    func onNextPageAction() -> Void {
        let _ = action!().done({_ in
            self.scanModel.notifyNextPage()
        })
    }
    
    func onPrevPageAction() -> Void {
        scanModel.prevPage()
        let _ = action!()
    }
    
    func doAction() -> Void {
        logger.info("scan bar on change action, scanModel: \(scanModel)")
        scanModel.resetHead()
        self.onNextPageAction()
    }
}
