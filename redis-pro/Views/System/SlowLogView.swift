//
//  SlowLogView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/7/14.
//

import SwiftUI

struct SlowLogView: View {
    @EnvironmentObject var redisInstanceModel:RedisInstanceModel
    
    @State private var slowerThan:Int = 10000
    @State private var maxLen:Int = 128
    
    @State private var datasource:[Any] = [SlowLogModel(), SlowLogModel()]
    @State private var selectIndex:Int?
    
    var body: some View {
        VStack(alignment: .leading, spacing: MTheme.V_SPACING) {
            // header
            HStack(alignment: .center, spacing: MTheme.H_SPACING) {
                FormItemInt(label: "Slower Than(microsecond)", labelWidth: 200, value: $slowerThan, suffix: "square.and.pencil", onCommit: onSlowerThanAction, autoCommit: false)
                    .help("UNIT_MICROSECOND")
                    .frame(width: 320)
                FormItemInt(label: "Max Len", value: $maxLen, suffix: "square.and.pencil", onCommit: onSlowerThanAction, autoCommit: false)
                    .help("UNIT_MICROSECOND")
                    .frame(width: 150)
                
                Spacer()
                MButton(text: "Reset", action: {})
            }
            
            SlowLogTable(datasource: $datasource, selectRowIndex: $selectIndex)
        }
    }
    
    func onSlowerThanAction() -> Void {
        
    }
}

struct SlowLogView_Previews: PreviewProvider {
    static var redisInstanceModel:RedisInstanceModel = RedisInstanceModel(redisModel: RedisModel())
    
    static var previews: some View {
        SlowLogView()
            .environmentObject(redisInstanceModel)
    }
}
