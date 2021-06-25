//
//  ClientModel.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/6/18.
//

import Foundation

class ClientModel:NSObject, Identifiable {
    @objc var id:Int = 0
    @objc var name:String = UUID().uuidString
    @objc var addr:String = ""
    @objc var fd:String = ""
    @objc var age:String = ""
    @objc var idle:String = ""
//    O ： 客户端是 MONITOR 模式下的附属节点（slave）
//    S ： 客户端是一般模式下（normal）的附属节点
//    M ： 客户端是主节点（master）
//    x ： 客户端正在执行事务
//    b ： 客户端正在等待阻塞事件
//    i ： 客户端正在等待 VM I/O 操作（已废弃）
//    d ： 一个受监视（watched）的键已被修改， EXEC 命令将失败
//    c : 在将回复完整地写出之后，关闭链接
//    u : 客户端未被阻塞（unblocked）
//    A : 尽可能快地关闭连接
//    N : 未设置任何 flag
    @objc var flags:String = ""
    @objc var db:String = ""
    @objc var sub:String = ""
    @objc var psub:String = ""
    @objc var multi:String = ""
    @objc var qbuf:String = ""
    @objc var qbuf_free:String = ""
    @objc var obl:String = ""
    @objc var oll:String = ""
    @objc var omem:String = ""
//    r : 客户端套接字（在事件 loop 中）是可读的（readable）
//    w : 客户端套接字（在事件 loop 中）是可写的（writeable）
    @objc var events:String = ""
    @objc var cmd:String = ""
    
    
}
