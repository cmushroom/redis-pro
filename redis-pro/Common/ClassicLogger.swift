//
//  LogManager.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/6/2.
//

import Foundation
import Logging
import XCGLogger

public struct ClassicLogHandler: LogHandler {
    private var xcgLogger:XCGLogger
    private var label: String
    
    public var logLevel: Logger.Level = .info
    
    public var metadata = Logger.Metadata()
    
    public subscript(metadataKey metadataKey: String) -> Logger.Metadata.Value? {
        get {
            return self.metadata[metadataKey]
        }
        set {
            self.metadata[metadataKey] = newValue
        }
    }
    
    public init(label: String, xcgLogger:XCGLogger) {
        self.label = label
        self.xcgLogger = xcgLogger
    }
    
    public func log(level: Logger.Level,
                    message: Logger.Message,
                    metadata: Logger.Metadata?,
                    source: String,
                    file: String = #file,
                    function: String = #function,
                    line: UInt = #line) {
        
        let xcgLoggerLevel = convert(level: level)
        xcgLogger.logln(xcgLoggerLevel, functionName: function, fileName: file, lineNumber: Int(line), userInfo: metadata ?? self.metadata) {
            return message
        }
    }
    
    
    func convert(level: Logger.Level) -> XCGLogger.Level {
        switch level {
        case .trace:
            return .verbose
            
        case .debug:
            return .debug
            
        case .info:
            return .info
            
        case .notice:
            return .notice
            
        case .warning:
            return .warning
            
        case .error:
            return .error
            
        case .critical:
            return .severe
        }
    }
}
