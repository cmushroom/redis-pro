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
                FormItemInt(label: "Max Len", value: $maxLen, suffix: "square.and.pencil", onCommit: onMaxLenAction)
                    .help("REDIS_SLOW_LOG_MAX_LEN")
                    .frame(width: 200)
                
            FormItemInt(label: "Size", value: $size, suffix: "square.and.pencil", onCommit: onSlowLogSizeChangeAction)
                .help("REDIS_SLOW_LOG_SIZE")
                .frame(width: 200)
                
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
            onRefreshAction()
        }
    }
    
    func onRefreshAction() -> Void {
        Task {
            await getSlowLog()
            await getSlowLogMaxLen()
            await getSlowLogSlowerThan()
        }
    }
    
    func onSlowerThanAction() -> Void {
        logger.info("update slow log slower than: \(self.slowerThan)")
        Task {
            let _ = await self.redisInstanceModel.getClient().setConfig(key: "slowlog-log-slower-than", value: "\(slowerThan)")
        }
    }
    
    func onMaxLenAction() -> Void {
        logger.info("update slow log max len: \(self.maxLen)")
        Task {
            let _ = await self.redisInstanceModel.getClient().setConfig(key: "slowlog-max-len", value: "\(maxLen)")
        }
    }
    
    func onSlowLogResetAction() -> Void {
        Task {
            let r = await self.redisInstanceModel.getClient().slowLogReset()
            if r {
                await self.getSlowLog()
            }
        }
    }
    
    func onSlowLogSizeChangeAction() -> Void {
        Task {
            await getSlowLog()
        }
    }
    
    func getSlowLog() async -> Void {
        let res = await self.redisInstanceModel.getClient().getSlowLog(self.size)
        self.datasource = res
        
        let total = await self.redisInstanceModel.getClient().slowLogLen()
        self.total = total
    }
    
    func getSlowLogMaxLen() async -> Void {
        let res = await self.redisInstanceModel.getClient().getConfigOne(key: "slowlog-max-len")
        self.maxLen = NumberHelper.toInt(res)
    }
    
    func getSlowLogSlowerThan() async -> Void {
        let res = await self.redisInstanceModel.getClient().getConfigOne(key: "slowlog-log-slower-than")
        self.slowerThan = NumberHelper.toInt(res)
    }
}

struct SlowLogView_Previews: PreviewProvider {
    static var redisInstanceModel:RedisInstanceModel = RedisInstanceModel(redisModel: RedisModel())
    
    static var previews: some View {
        SlowLogView()
            .environmentObject(redisInstanceModel)
    }
}
