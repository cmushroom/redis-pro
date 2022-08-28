//
//  ClientModel.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/6/18.
//
//"id", "name", "addr", "laddr", "fd", "age", "idle", "flags", "db", "sub", "psub", "multi", "qbuf", "qbuf-free", "obl", "oll", "omem", "events", "cmd", "argv-mem", "tot-mem", "redir", "user"

import Foundation

public class ClientModel:NSObject, Identifiable {
    @objc public var id:String = ""
    @objc var name:String = ""
    @objc var addr:String = ""
    @objc var laddr:String = ""
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
    @objc var argv_mem:String = ""
    @objc var tot_mem:String = ""
    @objc var redir:String = ""
    @objc var user:String = ""

    override init() {
    }
    
    init(line:String) {
        let kvStrArray = line.components(separatedBy: .whitespaces)
        
        var item:[String:String] = [String:String]()
        kvStrArray.forEach({kvStr in
            if kvStr.contains("=") {
                let kv = kvStr.components(separatedBy: "=")
                if kv.count == 2 {
                    item[kv[0]] = kv[1]
                }
            }
        })

        self.id = item["id"] ?? ""
        self.name = item["name"] ?? ""
        self.addr = item["addr"] ?? ""
        self.laddr = item["laddr"] ?? ""
        self.fd = item["fd"] ?? ""
        self.age = item["age"] ?? ""
        self.idle = item["idle"] ?? ""
        self.flags = item["flags"] ?? ""
        self.db = item["db"] ?? ""
        self.sub = item["sub"] ?? ""
        self.psub = item["psub"] ?? ""
        self.multi = item["multi"] ?? ""
        self.qbuf = item["qbuf"] ?? ""
        self.qbuf_free = item["qbuf-free"] ?? ""
        self.obl = item["obl"] ?? ""
        self.oll = item["oll"] ?? ""
        self.omem = item["omem"] ?? ""
        self.events = item["events"] ?? ""
        self.cmd = item["cmd"] ?? ""
        self.argv_mem = item["argv-mem"] ?? ""
        self.tot_mem = item["tot-mem"] ?? ""
        self.redir = item["redir"] ?? ""
        self.user = item["user"] ?? ""
        
    }
}
