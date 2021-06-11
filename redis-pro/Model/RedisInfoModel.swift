//
//  RedisInfoModel.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/6/10.
//
import Foundation

struct RedisInfoModel:Identifiable {
    var id = UUID()
    var section:String
    var infos:[(String, String)] = [(String, String)]()
}
