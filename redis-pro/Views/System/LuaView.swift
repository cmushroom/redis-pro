//
//  LuaView.swift
//  redis-pro
//
//  Created by chengpan on 2022/7/17.
//

import SwiftUI
import Logging
import ComposableArchitecture


struct LuaView: View {
    @Perception.Bindable var store:StoreOf<LuaStore>
    let logger = Logger(label: "lua-view")
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: MTheme.V_SPACING) {
            
            // header
            HStack(alignment: .center, spacing: MTheme.H_SPACING) {
                Text("Eval Lua Script")
                Spacer()
                MButton(text: "Script Flush", action: { store.send(.scriptFlush) })
            }
            
            VSplitView {
                VStack(alignment: .leading, spacing: MTheme.V_SPACING){
                    // text editor
                    MTextEditor(text: $store.lua)
                    
                    // btns
                    HStack(alignment: .center, spacing: MTheme.H_SPACING) {
//                            Text("Script SHA: \(store.luaSHA)")
                        Spacer()
//                            MButton(text: "Script Kill", action: { store.send(.scriptKill) })
//                            MButton(text: "Eval SHA", action: { store.send(.eval) })
                        MButton(text: "Eval", action: { store.send(.eval) }, keyEquivalent: .return)
                    }
                    .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
                    
                }
                
                MTextEditor(text: $store.evalResult)
            }
            
        }
        
    }
}

//struct LuaView_Previews: PreviewProvider {
//    static var previews: some View {
//        LuaView()
//    }
//}
