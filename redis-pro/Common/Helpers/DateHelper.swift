//
//  DateHelper.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/7/15.
//

import Foundation
import Logging

class DateHelper {
    
    static let logger = Logger(label: "number-helper")

    private static var dateTimeFormatter:DateFormatter = initDateTimeFormater()
    
    private static func initDateTimeFormater() -> DateFormatter {
        logger.info("初始化 datetime formatter...")
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT+8") //Set timezone that you want
        dateFormatter.locale = NSLocale.current
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss" //Specify your format that you want
        return dateFormatter
    }
    
    static func formatDateTime(timestamp:Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        return dateTimeFormatter.string(from: date)
    }
    
}
