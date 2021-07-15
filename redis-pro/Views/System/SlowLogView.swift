//
//  SlowLogView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/7/14.
//

import SwiftUI
import Logging

struct SlowLogView: View {
    @EnvironmentObject var redisInstanceModel:RedisInstanceModel
    
    @State private var slowerThan:Int = 10000
    @State private var maxLen:Int = 128
    @State private var size:Int = 50
    @State private var total:Int = 0
    
    @State private var datasource:[Any] = [SlowLogModel(), SlowLogModel()]
    @State private var selectIndex:Int?
    
    let logger = Logger(label: "slow-log-view")
    
    var body: some View {
        VStack(alignment: .leading, spacing: MTheme.V_SPACING) {
            // header
            HStack(alignment: .center, spacing: MTheme.H_SPACING) {
                FormItemInt(label: "Slower Than(us)", labelWidth: 120, value: $slowerThan, suffix: "square.and.pencil", onCommit: onSlowerThanAction, autoCommit: false)
                    .help("REDIS_SLOW_LOG_SLOWER_THAN")
                    .frame(width: 320)
                FormItemInt(label: "Max Len", value: $maxLen, suffix: "square.and.pencil", onCommit: onMaxLenAction, autoCommit: false)
                    .help("REDIS_SLOW_LOG_MAX_LEN")
                    .frame(width: 150)
                
            FormItemInt(label: "Size", value: $size, suffix: "square.and.pencil", onCommit: onSlowLogSizeChangeAction, autoCommit: true)
                .help("REDIS_SLOW_LOG_SIZE")
                .frame(width: 150)
                
                Spacer()
                MButton(text: "Reset", action: onSlowLogResetAction)
                    .help("REDIS_SLOW_LOG_RESET")
            }
            
            SlowLogTable(datasource: $datasource, selectRowIndex: $selectIndex)
            
            // footer
            HStack(alignment: .center, spacing: MTheme.H_SPACING_L) {
                Spacer()
                Text("Total: \(total)")
                    .font(.system(size: 12))
                    .help("REDIS_SLOW_LOG_TOTAL")
                Text("Current: \(datasource.count)")
                    .font(.system(size: 12))
                    .help("REDIS_SLOW_LOG_SIZE")
                IconButton(icon: "arrow.clockwise", name: "Refresh", action: onRefreshAction)
            }
            .padding(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
        }.onAppear {
            getSlowLog()
            getSlowLogMaxLen()
            getSlowLogSlowerThan()
        }
    }
    
    func onRefreshAction() -> Void {
        getSlowLog()
        getSlowLogMaxLen()
        getSlowLogSlowerThan()
    }
    
    func onSlowerThanAction() -> Void {
        logger.info("update slow log slower than: \(self.slowerThan)")
        let _ = self.redisInstanceModel.getClient().setConfig(key: "slowlog-log-slower-than", value: "\(maxLen)")
    }
    
    func onMaxLenAction() -> Void {
        logger.info("update slow log max len: \(self.maxLen)")
        let _ = self.redisInstanceModel.getClient().setConfig(key: "slowlog-max-len", value: "\(maxLen)")
    }
    
    func onSlowLogResetAction() -> Void {
        let _ = self.redisInstanceModel.getClient().slowLogReset().done({_ in
            self.getSlowLog()
        })
    }
    
    func onSlowLogSizeChangeAction() -> Void {
        getSlowLog()
    }
    
    func getSlowLog() -> Void {
        let _ = self.redisInstanceModel.getClient().getSlowLog(self.size).done({ res in
            self.datasource = res
        })
        
        let _ = self.redisInstanceModel.getClient().slowLogLen().done({ res in
            self.total = res
        })
    }
    
    func getSlowLogMaxLen() -> Void {
        let _ = self.redisInstanceModel.getClient().getConfigOne(key: "slowlog-max-len").done({ res in
            self.maxLen = NumberHelper.toInt(res)
        })
    }
    
    func getSlowLogSlowerThan() -> Void {
        let _ = self.redisInstanceModel.getClient().getConfigOne(key: "slowlog-log-slower-than").done({ res in
            self.slowerThan = NumberHelper.toInt(res)
        })
    }
}

struct SlowLogView_Previews: PreviewProvider {
    static var redisInstanceModel:RedisInstanceModel = RedisInstanceModel(redisModel: RedisModel())
    
    static var previews: some View {
        SlowLogView()
            .environmentObject(redisInstanceModel)
    }
}
