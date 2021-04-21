//
//  KeyValueRowEditorView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/9.
//

import SwiftUI
import Logging

struct KeyValueRowEditorView: View {
    @State var text:String = ""
    @State var hashMap:[String: String?] = ["testesttesttesttesttesttesttesttesttesttesttestt":"234243242343"]
    @State var selectKey:String?
    @State var isEditing:Bool = false
    @EnvironmentObject var redisInstanceModel:RedisInstanceModel
    @EnvironmentObject var globalContext:GlobalContext
    @ObservedObject var redisKeyModel:RedisKeyModel
    @StateObject var page:Page = Page()
    
    let logger = Logger(label: "redis-editor-kv")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center , spacing: 4) {
                IconButton(icon: "plus", name: "Add", action: onDeleteAction)
                IconButton(icon: "trash", name: "Delete", action: onDeleteAction)
                
                SearchBar(keywords: $page.keywords, placeholder: "Search field...", action: onQueryField)
                
                Spacer()
                PageBar(page:page)
            }
            .padding(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
            
            GeometryReader { proxy in
                List(selection: $selectKey) {
                    //                    HStack {
                    //                        Text("Field")
                    //                            .frame(width: proxy.size.width/2, alignment: .leading)
                    //                        Text("Value")
                    //                            .frame(width: proxy.size.width/2, alignment: .leading)
                    //                            .padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 0))
                    //                            .border(width:1, edges: [.leading], color: Color.gray)
                    //                    }
                    //                    .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
                    //                    .background(Color.gray.opacity(0.4))
                    
                    
                    Section(header: HStack {
                        Text("Field")
                            .frame(width: proxy.size.width/2, alignment: .leading)
                        Text("Value")
                            .frame(width: proxy.size.width/2, alignment: .leading)
                            .padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 0))
                            .border(width:1, edges: [.leading], color: Color.gray)
                    }) {
                        
                        ForEach(Array(hashMap.keys), id:\.self) { key in
                            
                            HStack {
                                
                                Text(key)
                                    .frame(width: proxy.size.width/2, alignment: .leading)
                                Text((hashMap[key] ?? "")!)
                                    .multilineTextAlignment(.leading)
                                    .frame(width: proxy.size.width/2, alignment: .leading)
                            }
                            .background(Color.blue.opacity(0.1))
                        }
                    }
                    .collapsible(false)
                    
                }
                //                }
            }
            .listStyle(PlainListStyle())
            .padding(.all, 0)
            //                    .frame(minWidth: 100, maxWidth: .infinity, minHeight: 100, maxHeight: .infinity, alignment: .topLeading)
            
           
            
            // footer
            HStack(alignment: .center, spacing: 4) {
                Spacer()
                IconButton(icon: "arrow.clockwise", name: "Refresh", action: onRefreshAction)
                IconButton(icon: "checkmark", name: "Submit", confirmPrimaryButtonText: "Submit", action: onSubmitAction)
            }
            .padding(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
        }
        .onChange(of: redisKeyModel, perform: { value in
            logger.info("redis string value editor view change \(value)")
            onLoad(value)
        })
        .onAppear {
            logger.info("redis string value editor view init...")
            onLoad(redisKeyModel)
        }
    }
    
    func onDeleteAction() -> Void {
        print("hash field delete action...")
    }
    func onQueryField() throws -> Void {
        try queryHashPage(redisKeyModel)
    }
    
    func onSubmitAction() throws -> Void {
        logger.info("redis string value editor on submit")
        //        try redisInstanceModel.getClient().set(redisKeyModel.key, value: text, ex: redisKeyModel.ttl)
    }
    
    func onRefreshAction() throws -> Void {
        try queryHashPage(redisKeyModel)
        try ttl(redisKeyModel)
    }
    
    func onLoad(_ redisKeyModel:RedisKeyModel) -> Void {
        do {
            try queryHashPage(redisKeyModel)
        } catch {
            logger.error("on string editor view load query redis hash error:\(error)")
            globalContext.showError(error)
        }
    }
    
    func queryHashPage(_ redisKeyModel:RedisKeyModel) throws -> Void {
        hashMap = try redisInstanceModel.getClient().pageHashEntry(redisKeyModel.key, page: page)
    }
    
    func ttl(_ redisKeyModel:RedisKeyModel) throws -> Void {
        redisKeyModel.ttl = try redisInstanceModel.getClient().ttl(key: redisKeyModel.key)
    }
}

struct KeyValueRowEditorView_Previews: PreviewProvider {
    static var redisKeyModel:RedisKeyModel = RedisKeyModel(key: "tes", type: "string")
    static var previews: some View {
        KeyValueRowEditorView(redisKeyModel: redisKeyModel)
    }
}



struct EdgeBorder: Shape {
    
    var width: CGFloat
    var edges: [Edge]
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        for edge in edges {
            var x: CGFloat {
                switch edge {
                case .top, .bottom, .leading: return rect.minX
                case .trailing: return rect.maxX - width
                }
            }
            
            var y: CGFloat {
                switch edge {
                case .top, .leading, .trailing: return rect.minY
                case .bottom: return rect.maxY - width
                }
            }
            
            var w: CGFloat {
                switch edge {
                case .top, .bottom: return rect.width
                case .leading, .trailing: return self.width
                }
            }
            
            var h: CGFloat {
                switch edge {
                case .top, .bottom: return self.width
                case .leading, .trailing: return rect.height
                }
            }
            path.addPath(Path(CGRect(x: x, y: y, width: w, height: h)))
        }
        return path
    }
}

extension View {
    func border(width: CGFloat, edges: [Edge], color: Color) -> some View {
        overlay(EdgeBorder(width: width, edges: edges).foregroundColor(color))
    }
}
