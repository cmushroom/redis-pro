//
//  StringHelper.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/7/16.
//

import Foundation
import Logging

class StringHelper {
    
    static let logger = Logger(label: "string-helper")
    
    static func ellipses(_ text:String, len:Int = 8) -> String{
        if text.count <= len {
            return text
        }
        var newText = text.substring(to: len)
        newText.append("...")
        return newText
    }
}

extension String {
    func index(from: Int) -> Index {
        return self.index(startIndex, offsetBy: from)
    }

    func substring(from: Int) -> String {
        let fromIndex = index(from: from)
        return String(self[fromIndex...])
    }

    func substring(to: Int) -> String {
        let toIndex = index(from: to)
        return String(self[..<toIndex])
    }

    func substring(with r: Range<Int>) -> String {
        let startIndex = index(from: r.lowerBound)
        let endIndex = index(from: r.upperBound)
        return String(self[startIndex..<endIndex])
    }
}
