//
//  NumberFormatterHelper.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/5/8.
//

import Foundation
import Logging

class NumberHelper {
    static let logger = Logger(label: "redis-set-editor")
    
    static var formatter:NumberFormatter = {
        logger.info("NumberFormatHelper init number formatter instance ...")
        
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.numberStyle = .decimal
        formatter.hasThousandSeparators = false
        formatter.maximumIntegerDigits = 50
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 8
        formatter.generatesDecimalNumbers = true
        formatter.maximumSignificantDigits = 50
        return formatter
    }()
    
    static func formatDouble(_ value:Double?, defaultValue:String? = "-") -> String {
        if value == nil {
            return defaultValue ?? "-"
        }
        
        let r = formatter.string(for: NSNumber(value: value!))
        
        if r == nil {
            return defaultValue ?? "-"
        }
        return r!
    }
    
    static func toInt(_ value:Any?, defaultValue:Int? = 0) -> Int {
        if value == nil {
            return defaultValue!
        }
        
        let r = formatter.number(from: String(describing: value))?.intValue
        
        if r == nil {
            return defaultValue!
        }
        return r!
    }
    
    
}
