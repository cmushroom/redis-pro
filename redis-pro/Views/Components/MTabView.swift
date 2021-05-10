//
//  MTabView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/5/10.
//

import SwiftUI

struct MTabView: View {
    var keys:[String] = ["a", "b", "c"]
    @State var selected:Int = 0
    
    var body: some View {
        Picker(selection: $selected, label: Text("Favorite Color")) {
                        Text("Red").tag(1)
                        Text("Green").tag(2)
                        Text("Blue").tag(3)
                        Text("Other").tag(4)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .horizontalRadioGroupLayout()
    }
}

struct MTabView_Previews: PreviewProvider {
    static var previews: some View {
        MTabView()
    }
}
