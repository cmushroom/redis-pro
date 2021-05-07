//
//  StringFormatter.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/5/7.
//

import Foundation

public class StringFormatter: Formatter {

    override public func string(for obj: Any?) -> String? {
        var retVal: String?

        if let str = obj as? String {
            retVal = str.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            retVal = nil
        }

        return retVal
    }

    override public func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        return true
    }
}
