//
//  RedisIdleHandler.swift
//  redis-pro
//
//  Created by chengpan on 2024/1/21.
//

import Logging
import Foundation
import NIO
import NIOConcurrencyHelpers

class RedisIdleHandler: ChannelInboundHandler {
    typealias InboundIn = ByteBuffer
    typealias OutboundOut = ByteBuffer
    
    private let logger = Logger(label: "redis-idle-handler")
    
    func userInboundEventTriggered(context: ChannelHandlerContext, event: Any) {
        logger.info("redis idle handler triggerd!")
        if let idleStateEvent = event as? IdleStateHandler.IdleStateEvent {
            logger.info("Client timed out")
            context.close(promise: nil)
        }
        
        // 继续传播事件
        context.fireUserInboundEventTriggered(event)
    }
}
