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
    @State var selectField:String?
    @State var isEditing:Bool = false
    @EnvironmentObject var redisInstanceModel:RedisInstanceModel
    @EnvironmentObject var globalContext:GlobalContext
    @ObservedObject var redisKeyModel:RedisKeyModel
    @StateObject var page:Page = Page()
    @State var focusKey = "14"
    
    
    var delButtonDisabled:Bool {
        selectField == nil
    }
    
    let logger = Logger(label: "redis-editor-kv")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center , spacing: 4) {
                IconButton(icon: "plus", name: "Add", action: onDeleteAction)
                IconButton(icon: "trash", name: "Delete", disabled:delButtonDisabled,
                           isConfirm: true,
                           confirmTitle: String(format: Helps.DELETE_HASH_FIELD_CONFIRM_TITLE, selectField ?? ""),
                           confirmMessage: String(format:Helps.DELETE_HASH_FIELD_CONFIRM_MESSAGE, selectField ?? ""),
                           confirmPrimaryButtonText: "Delete",
                           action: onDeleteAction)
                
                SearchBar(keywords: $page.keywords, placeholder: "Search field...", action: onQueryField)
                
                Spacer()
                PageBar(page:page)
            }
            .padding(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
            
//            GeometryReader { geometry in
//                let width0 = geometry.size.width/2
//                let width1 = width0
//                ScrollView {
//                    ForEach(Array(hashMap.keys), id:\.self) { key in
//                        HStack {
//                            Text(key)
//
//                                .font(.body)
//                                .frame(width: width0, alignment: .leading)
//                            TextField("Line 1", text: $text)
//                                .font(.body)
//                                .multilineTextAlignment(.leading)
//                                .frame(width: width1, alignment: .leading)
//                        }
//                        .background(key == "34" ? Color.blue : nil)
//                        .border(Color.gray, width: 1)
//                        .onTapGesture(count: 2) {
//                            print("on double tap")
//                        }
//                        .onTapGesture(count: 1) {
//                            print("on tap")
//                        }
//                    }
//                }
//                .background(Color.white)
//            }
            
            TextField("", text: $text)
                .introspectTextField { textField in
                    textField.becomeFirstResponder()
                }

            GeometryReader { geometry in
                let width0 = geometry.size.width/2
                let width1 = width0

                List(selection: $selectField) {
                    Section(header: HStack {
                        Text("Field")
                            .frame(width: width0, alignment: .leading)
                        Text("Value")
                            .frame(width: width1, alignment: .leading)
                            .padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 0))
                            .border(width:1, edges: [.leading], color: Color.gray)
                    }) {

                        ForEach(Array(hashMap.keys), id:\.self) { key in
                            HStack {
                                Text(key)
                                    .onTapGesture {
                                        print("on text tap")
                                    }
                                    .font(.body)
                                    .frame(width: width0, alignment: .leading)
                                TextField("Line 1", text: $text)
                                    .focusable(key == focusKey, onFocusChange: {_ in
                                        print("focused \(key)")
                                    })
                                    .font(.body)
                                    .multilineTextAlignment(.leading)
                                    .frame(width: width1, alignment: .leading)
                            }
                            .contextMenu {
                                Button(action: {
                                    // delete item in items array
                                }){
                                    Text("Edit")
                                }
                                Button(action: {
                                    // delete item in items array
                                }){
                                    Text("Delete")
                                }
                            }
                            .padding(EdgeInsets(top: 4, leading: 2, bottom: 4, trailing: 2))
                            .overlay(
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(Color.gray.opacity(0.1)),
                                alignment: .bottom
                            )
                            .listRowInsets(EdgeInsets())
                        }
                    }
                    .collapsible(false)

                }
                .listStyle(PlainListStyle())
                .padding(.all, 0)
            }
            
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
    
    func onDeleteAction() throws -> Void {
        logger.info("hash field delete action...")
        let r = try redisInstanceModel.getClient().hdel(redisKeyModel.key, field: selectField!)
        if r > 0 {
            hashMap.removeValue(forKey: selectField!)
        }
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
