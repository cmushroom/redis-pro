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
        HStack(alignment:.center) {
            Spacer()
            Text("Total:\(page.total)")
//                .help(Helps.PAGE_KEYS)
                .font(.footnote)
                .padding(.leading, 4.0)
            
            //            Spacer()
            Picker("", selection: $page.size) {
                Text("50").tag(50)
                Text("100").tag(100)
                Text("200").tag(200)
                Text("500").tag(500)
            }
            .onChange(of: page.size, perform: { value in
                logger.info("on page size change: \(value)")
                doAction()
            })
            .font(/*@START_MENU_TOKEN@*/.footnote/*@END_MENU_TOKEN@*/)
            .frame(width: 70)
            HStack(alignment:.center) {
                MIcon(icon: "chevron.left", action: doAction).disabled(!page.hasPrevPage)
                Text("\(page.current)/\(page.totalPage)")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                //                    .layoutPriority(1)
                MIcon(icon: "chevron.right", action: doAction).disabled(!page.hasNextPage)
            }
            .layoutPriority(1)
        }
        .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
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
