//
//  ReadTimeoutHandler.swift
//  redis-pro
//
//  Created by chengpan on 2024/1/13.
//

import Logging
import Foundation
import NIO
import NIOConcurrencyHelpers

class ReadTimeoutHandler: ChannelInboundHandler {
    typealias InboundIn = Any
    
    private let timeout: TimeAmount
    private var scheduledTimeout: Scheduled<Void>?
    
    private let logger = Logger(label: "nio-timeout-handler")
    
    init(timeout: TimeAmount) {
        self.timeout = timeout
    }
    
    func channelActive(context: ChannelHandlerContext) {
        // 当通道激活时，设置读取超时事件
        self.scheduledTimeout = context.eventLoop.scheduleTask(in: self.timeout) {
            // 处理读取超时逻辑，例如关闭通道或发出读取超时错误
            self.logger.info("NIO read timed out!")
            context.close(promise: nil)
        }
        
        // 继续传递通道激活事件
        context.fireChannelActive()
    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        // 当有数据可读时，重置读取超时事件
        self.scheduledTimeout?.cancel()
        self.scheduledTimeout = context.eventLoop.scheduleTask(in: self.timeout) {
            // 处理读取超时逻辑，例如关闭通道或发出读取超时错误
            self.logger.info("NIO read timed out!")
            context.close(promise: nil)
        }
        
        // 继续传递读取事件
        context.fireChannelRead(data)
    }
    
    func channelInactive(context: ChannelHandlerContext) {
        // 当通道非活动时，取消已计划的读取超时事件
        self.scheduledTimeout?.cancel()
        
        // 继续传递通道非活动事件
        context.fireChannelInactive()
    }
}
