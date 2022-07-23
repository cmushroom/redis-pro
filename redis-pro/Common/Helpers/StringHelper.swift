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
        var newText = text.substr(to: len)
        newText.append("...")
        return newText
    }
    
    static func format(_ template:String, _ params:String...) -> String {
        
        return String(format: localized(template), arguments: params)
    }
    
    static func localized(_ template:String) -> String {
        
        return NSLocalizedString(template, comment: "")
    }
    
    static func trim(_ v:String) -> String {
        return v.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    static func split(_ v:String, isTrim: Bool = true) -> [String] {
        return v.components(separatedBy: .whitespacesAndNewlines).map {
            isTrim ? self.trim($0) : $0
        }
    }
    
    static func split(_ v:String) -> [String] {
       return split(v, isTrim: true)
    }
    
    static func startWith(_ v:String, start: String) -> Bool {
        return v.hasPrefix(start)
    }
    
    static func startWithIgnoreCase(_ v:String, start: String) -> Bool {
        return v.lowercased().hasPrefix(start.lowercased())
    }
    
    
    static func removeStart(_ v:String, start: String) -> String {
        guard v.hasPrefix(start) else { return v }
        return String(v.dropFirst(start.count))
    }
    
    
    static func removeStartIgnoreCase(_ v:String, start: String) -> String {
        guard startWithIgnoreCase(v, start: start) else { return v }
        return String(v.dropFirst(start.count))
    }
}

extension String {
    var length: Int {
        return count
    }
    
    
    subscript (i: Int) -> String {
        return self[i ..< i + 1]
    }
    
    subscript (r: Range<Int>) -> String {
        let range = Range(uncheckedBounds: (lower: max(0, min(length, r.lowerBound)),
                                            upper: min(length, max(0, r.upperBound))))
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(start, offsetBy: range.upperBound - range.lowerBound)
        return String(self[start ..< end])
    }
    
    func indexOf(_ input: String,
                 options: String.CompareOptions = .literal) -> String.Index? {
        return self.range(of: input, options: options)?.lowerBound
    }
    
    func lastIndexOf(_ input: String) -> String.Index? {
        return indexOf(input, options: .backwards)
    }
    
    func index(from: Int) -> Index {
        return self.index(startIndex, offsetBy: from)
    }
    
    func substr(from: Int) -> String {
        let fromIndex = index(from: from)
        return String(self[fromIndex...])
    }
    
    func substr(from: String.Index) -> String {
        return String(self[from...])
    }
    
    func substr(to: Int) -> String {
        let toIndex = index(from: to)
        return String(self[..<toIndex])
    }

    func substr(to: String.Index) -> String {
        return String(self[..<to])
    }
    
    func substr(_ r: Range<Int>) -> String {
        let startIndex = index(from: r.lowerBound)
        let endIndex = index(from: r.upperBound)
        return String(self[startIndex..<endIndex])
    }
}
