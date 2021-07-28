//
//  PageBar.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/12.
//

import SwiftUI
import Logging

struct PageBar: View {
    @EnvironmentObject var globalContext:GlobalContext
    @ObservedObject var page:Page
    var action:() throws -> Void = {}
    var showTotal:Bool = true
    
    let logger = Logger(label: "page-bar")
    
    var body: some View {
        HStack(alignment:.center, spacing: 4) {
            Spacer()
            if showTotal {
                Text("Total: \(page.total)")
                    .font(MTheme.FONT_FOOTER)
                    .lineLimit(1)
                    .multilineTextAlignment(.trailing)
            }
            
            Picker("", selection: $page.size) {
                Text("10").tag(10)
                Text("50").tag(50)
                Text("100").tag(100)
                Text("200").tag(200)
            }
            .onChange(of: page.size, perform: { value in
                logger.info("on page size change: \(value)")
                page.firstPage()
                doAction()
            })
            .font(MTheme.FONT_FOOTER)
            .frame(width: 65)
            
            HStack(alignment:.center, spacing: 2) {
                MIcon(icon: "chevron.left", action: onPrevPageAction).disabled(!page.hasPrev && !globalContext.loading)
                Text("\(page.current)/\(page.totalPage)")
                    .font(MTheme.FONT_FOOTER)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .layoutPriority(1)
                MIcon(icon: "chevron.right", action: onNextPageAction).disabled(!page.hasNext && !globalContext.loading)
            }
            .frame(minWidth: 60, idealWidth: 60)
        }
    }
    
    func onNextPageAction() -> Void {
        page.nextPage()
        doAction()
    }
    
    func onPrevPageAction() -> Void {
        page.prevPage()
        doAction()
    }
    
    func doAction() -> Void {
        logger.info("page bar change action, page: \(page)")
        do {
            try action()
        } catch {
            globalContext.showError(error)
        }
    }
}

struct PageBar_Previews: PreviewProvider {
    static var previews: some View {
        PageBar(page: Page())
    }
}
