//
//  KeyValueRowEditorView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/9.
//

import SwiftUI

struct KeyValueRowEditorView: View {
    @State var text:String = ""
    @State var hashMap:[String: String] = ["testesttesttesttesttesttesttesttesttesttesttestt":"234243242343", "test1":"2342"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center , spacing: 4) {
                IconButton(icon: "plus", name: "Add", action: onDeleteAction)
                IconButton(icon: "trash", name: "Delete", action: onDeleteAction)
                Spacer()
            }
            .padding(EdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6))
            
            List() {
                //                TextField("test", text: $text).environment(\.isEnabled, true)
                //                    .textFieldStyle(PlainTextFieldStyle())
                LazyVGrid(columns: Array(repeating: GridItem(), count: 2), alignment: .leading, spacing: 20) {
                    Text("Field")
                    Text("Value")
                        .padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 0))
                        .border(width:1, edges: [.leading], color: Color.gray)
                }
                .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
                .background(Color.gray.opacity(0.4))
                LazyVGrid(columns: Array(repeating: GridItem(), count: 2), alignment: .leading, spacing: 20) {
                    
                    
                    ForEach(hashMap.sorted(by: >), id:\.key) { key, value in
                        //                    Text(key)
                        //                        .multilineTextAlignment(.leading)
                        TextField("Key", text: $text)
                        Text(value)
                            .multilineTextAlignment(.leading)
                    }
                }
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
