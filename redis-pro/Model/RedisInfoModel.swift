//
//  RedisInfoModel.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/6/10.
//
import Foundation

public class RedisInfoModel:NSObject, Identifiable {
    public var id = UUID()
    var section:String = ""
    var infos:[RedisInfoItemModel] = [RedisInfoItemModel]()
    
    override init() {
    }
    
    init(section:String) {
        self.section = section
    }
}
