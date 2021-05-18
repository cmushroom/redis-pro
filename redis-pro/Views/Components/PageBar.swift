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
    
    let logger = Logger(label: "page-bar")
    
    var body: some View {
        HStack(alignment:.center, spacing: 4) {
            Spacer()
            Text("Total: \(page.total)")
                .font(.footnote)
                .lineLimit(1)
                .multilineTextAlignment(.trailing)
            
            Picker("", selection: $page.size) {
                Text("10").tag(10)
                Text("50").tag(50)
                Text("100").tag(100)
                Text("200").tag(200)
            }
            .help(Helps.PAGE_SIZE)
            .onChange(of: page.size, perform: { value in
                logger.info("on page size change: \(value)")
                page.firstPage()
                doAction()
            })
            .font(.footnote)
            .frame(width: 60)
            
            HStack(alignment:.center) {
                MIcon(icon: "chevron.left", action: onPrevPageAction).disabled(!page.hasPrevPage)
                Text("\(page.current)/\(page.totalPage)")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                MIcon(icon: "chevron.right", action: onNextPageAction).disabled(!page.hasNextPage)
            }
            .layoutPriority(1)
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
