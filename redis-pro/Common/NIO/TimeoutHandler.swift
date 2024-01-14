//
//  TimeoutHandler.swift
//  redis-pro
//
//  Created by chengpan on 2024/1/13.
//

import Foundation
import NIO

class TimeoutHandler: ChannelInboundHandler {
    typealias InboundIn = ByteBuffer

    private var scheduledTimeout: Scheduled<Void>?

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        // 处理接收到的数据
        // ...
        // 如果接收到预期的数据，取消超时任务
        cancelTimeout()
    }

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        // 处理错误
        // ...

        // 如果发生错误，取消超时任务
        cancelTimeout()
        context.fireErrorCaught(error)
    }

    private func setupTimeout(context: ChannelHandlerContext, timeout: TimeAmount) {
        // 如果已经设置了超时任务，取消它
        cancelTimeout()

        // 安排一个新的超时任务
        scheduledTimeout = context.eventLoop.scheduleTask(in: timeout) {
            self.timeoutExpired(context: context)
        }
    }

    private func cancelTimeout() {
        // 取消超时任务
        scheduledTimeout?.cancel()
        scheduledTimeout = nil
    }

    private func timeoutExpired(context: ChannelHandlerContext) {
        // 处理超时
        // ...

        // 关闭连接或执行其他操作
        context.close(promise: nil)
    }
}
