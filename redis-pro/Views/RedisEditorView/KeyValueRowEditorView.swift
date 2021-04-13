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
    @State var hashMap:[String: String] = ["testesttesttesttesttesttesttesttesttesttesttestt":"234243242343"]
    @State var selectKey:String?
    @State var isEditing:Bool = false
    
    let logger = Logger(label: "redis-editor-kv")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center , spacing: 4) {
                IconButton(icon: "plus", name: "Add", action: onDeleteAction)
                IconButton(icon: "trash", name: "Delete", action: onDeleteAction)
                
                SearchBar(placeholder: "Search field...", action: {k in
                    logger.info("on search commit: \(k)")
                })

                Spacer()
                PageBar()
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
                    }
//                    .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
//                    .background(Color.gray.opacity(0.4))
                    ) {
                    ForEach(hashMap.sorted(by: >), id:\.key) { key, value in
                        
                        HStack {
                            
                            TextField("text field", text: $text).environment(\.isEnabled, true)
                                .focusable(true)
                                .textFieldStyle(PlainTextFieldStyle())
                                .frame(width: proxy.size.width/2, alignment: .leading)
                            Text(value)
                                .multilineTextAlignment(.leading)
                                .frame(width: proxy.size.width/2, alignment: .leading)
                                .onTapGesture(count: 2) {
                                               print("double clicked")
                                           }
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
            
            
        }
    }
    
    func onDeleteAction() -> Void {
        print("hash field delete action...")
    }
}

struct KeyValueRowEditorView_Previews: PreviewProvider {
    static var previews: some View {
        KeyValueRowEditorView()
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
