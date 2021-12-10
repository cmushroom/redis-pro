//
//  NumberFormatterHelper.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/5/8.
//

import Foundation
import Logging

class NumberHelper {
    static let logger = Logger(label: "number-helper")
    
    static var doubleFormatter:NumberFormatter = {
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
    
    
    static var intFormatter:NumberFormatter = {
        logger.info("NumberFormatHelper init number formatter instance ...")
        
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.numberStyle = .decimal
        formatter.hasThousandSeparators = false
        formatter.maximumIntegerDigits = 20
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        formatter.generatesDecimalNumbers = true
        formatter.maximumSignificantDigits = 20
        return formatter
    }()
    
    static func formatDouble(_ value:Double?, defaultValue:String? = "-") -> String {
        if value == nil {
            return defaultValue ?? "-"
        }
        
        let r = doubleFormatter.string(for: NSNumber(value: value!))
        
        if r == nil {
            return defaultValue ?? "-"
        }
        return r!
    }
    
    static func toInt(_ value:Any?, defaultValue:Int? = 0) -> Int {
        if value == nil {
            return defaultValue!
        }
        
        let r = intFormatter.number(from: "\(value!)")?.intValue
        
        if r == nil {
            return defaultValue!
        }
        return r!
    }
    
    
    static func isInt(_ value:String?) -> Bool {
        if value == nil {
            return false
        }
        
        return Int(value!)  != nil
    }
    
}
