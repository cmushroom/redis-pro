//
//  Objects.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/6/18.
//

import Foundation

struct Objects {
    
    static func toDic(mirror: Mirror) -> [String: Any] {
        var dic: [String: Any] = [:]
        for child in mirror.children {
            // 如果没有labe就会被抛弃
            if let label = child.label {
                let propertyMirror = Mirror(reflecting: child.value)
                print(propertyMirror)
                dic[label] = child.value
            }
        }
        // 添加父类属性
        if let superMirror = mirror.superclassMirror {
            let superDic = toDic(mirror: superMirror)
            for p in superDic {
                dic[p.key] = p.value
            }
        }
        return dic
    }
}
