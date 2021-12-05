//
//  Demo.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/6/21.
//

import SwiftUI
import AppKit
import Cocoa

struct Demo: View {
    @State var selection:Int?
    @State var value:String = ""
    
    var body: some View {
        VStack(spacing: 10) {
            NTextField(stringValue: $value, placeholder: "placeholder")
            if #available(macOS 12.0, *) {
                TextField("label", text: $value, prompt: Text("placeholder"))
            }
            Text("text")
            
            Menu(content: {
                Button("1", action: {})
                Button("2", action: {})
                Button("3", action: {})
            }, label: {
                MLabel(name: "DB1", icon: "cylinder.split.1x2", size: .S).font(.system(size: 8))
            })
            .menuButtonStyle(PullDownMenuButtonStyle())
            
            Menu(content: {
                Button("1", action: {})
                Button("2", action: {})
                Button("3", action: {})
            }, label: {
                MLabel(name: "DB1", icon: "cylinder.split.1x2", size: .S).font(.system(size: 8))
            })
            .menuButtonStyle(BorderlessPullDownMenuButtonStyle())
            
            Menu(content: {
                Button("1", action: {})
                Button("2", action: {})
            }, label: {
                MLabel(name: "DB1", icon: "cylinder.split.1x2", size: .S).font(.system(size: 8))
            })
            .menuStyle(DefaultMenuStyle())
            Menu(content: {
                Button("1", action: {})
                Button("2", action: {})
            }, label: {
                MLabel(name: "DB1", icon: "cylinder.split.1x2", size: .S).font(.system(size: 8))
            })
            .menuStyle(BorderedButtonMenuStyle())
            Menu(content: {
                Button("1", action: {})
                Button("2", action: {})
            }, label: {
                MLabel(name: "DB1", icon: "cylinder.split.1x2", size: .M).font(.system(size: 8))
                
//                Image(systemName: "cylinder.split.1x2").resizable().scaleEffect(0.2)
//                Label(
//                    title: { Text("DB").font(.system(size: 10)) },
//                    icon: { Image(systemName: "cylinder.split.1x2").resizable().scaleEffect(0.5) }
//                )
                
            })
            .menuStyle(BorderlessButtonMenuStyle())
            .scaleEffect(0.9)
            .frame(width: 50)
            
            
            MenuButton(label:
                        MLabel(name: "DB1", icon: "cylinder.split.1x2", size: .S).font(.system(size: 8))
//                        .scaleEffect(.l)
    //                    Text("􀡓 DB\(database)")
    //                    .foregroundColor(.primary)
    //                    .font(.system(size: 10.0))
            ){
                Button("1", action: {})
                Button("1", action: {})
                Button("1", action: {})
            }
            .menuButtonStyle(BorderlessPullDownMenuButtonStyle())
            
            
        }.padding(10)
    }
}

struct Demo_Previews: PreviewProvider {
    static var previews: some View {
        Demo()
            .frame(width: 600, height: 400, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
    }
}
