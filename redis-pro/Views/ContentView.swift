//
//  ContentView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/1/19.
//

import SwiftUI

struct ContentView: View {
    var modelData:ModelData = ModelData()
    var body: some View {
        LandmarkList()
            .environmentObject(modelData)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
