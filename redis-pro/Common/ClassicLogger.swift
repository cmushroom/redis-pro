//
//  LogManager.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/6/2.
//

import Foundation
import Logging

public struct ClassicLogHandler: LogHandler {
    private let logger: ClassicLogger = ClassicLogger()
//    private let stream: TextOutputStream = StreamLogHandler.
    private let label: String

    public var logLevel: Logger.Level = .info

    private var prettyMetadata: String?
    public var metadata = Logger.Metadata() {
        didSet {
            self.prettyMetadata = self.prettify(self.metadata)
        }
    }

    public subscript(metadataKey metadataKey: String) -> Logger.Metadata.Value? {
        get {
            return self.metadata[metadataKey]
        }
        set {
            self.metadata[metadataKey] = newValue
        }
    }
    
    init(label: String) {
        self.label = label
    }
    
    public func log(level: Logger.Level, message: Logger.Message, metadata: Logger.Metadata?, file: String, function: String, line: UInt) {
        let prettyMetadata = metadata?.isEmpty ?? true
            ? self.prettyMetadata
            : self.prettify(self.metadata.merging(metadata!, uniquingKeysWith: { _, new in new }))

//        var stream = self.stream
        print("\(self.timestamp()) \(level) \(self.label) :\(prettyMetadata.map { " \($0)" } ?? "") \(message)\n")
    }
    
    private func prettify(_ metadata: Logger.Metadata) -> String? {
        return !metadata.isEmpty ? metadata.map { "\($0)=\($1)" }.joined(separator: " ") : nil
    }
    
    private func timestamp() -> String {
        var buffer = [Int8](repeating: 0, count: 255)
        var timestamp = time(nil)
        let localTime = localtime(&timestamp)
        strftime(&buffer, buffer.count, "%Y-%m-%dT%H:%M:%S%z", localTime)
        return buffer.withUnsafeBufferPointer {
            $0.withMemoryRebound(to: CChar.self) {
                String(cString: $0.baseAddress!)
            }
        }
    }
    
    func getFile() -> Void {
//        FileManager.default.url(for: .allLibrariesDirectory, in: .localDomainMask, appropriateFor: <#T##URL?#>, create: <#T##Bool#>)
    }
    
}


//    let logger = Logger(label: "log-file")
//
//    func write(_ text: String) {
//        logger.info("init log file...")
//        guard let data = text.data(using: String.Encoding.utf8) else {
//          return
//        }
////        FileHandle.standardError.write(data)
//
//        let manager = FileManager.default
//        let logFile = "/var/log/redis.log"
//        let exist = manager.fileExists(atPath: logFile)
//        if !exist {
//            logger.info("create log file...")
//            manager.createFile(atPath: logFile, contents: nil)
//        }
//        FileHandle(forWritingAtPath: logFile)?.write(data)
//    }

struct ClassicLogger{
    
}

extension Logger.Level {
    var color: TerminalColor {
        switch self {
        case .warning:
            return .yellow
        case .error:
            return .red
        default:
            return .foreground
        }
    }
}

/// The set of colors used when logging with colorized lines.
public enum TerminalColor: String {
    /// Log text in white.
    case white = "\u{001B}[0;37m" // white
    /// Log text in red, used for error messages.
    case red = "\u{001B}[0;31m" // red
    /// Log text in yellow, used for warning messages.
    case yellow = "\u{001B}[0;33m" // yellow
    /// Log text in the terminal's default foreground color.
    case foreground = "\u{001B}[0;39m" // default foreground color
    /// Log text in the terminal's default background color.
    case background = "\u{001B}[0;49m" // default background color
}

public enum LoggerMessageType : Int {
    
    /// Log message type for logging when entering into a function.
    case entry
    
    /// Log message type for logging when exiting from a function.
    case exit
    
    /// Log message type for logging a debugging message.
    case debug
    
    /// Log message type for logging messages in verbose mode.
    case verbose
    
    /// Log message type for logging an informational message.
    case info
    
    /// Log message type for logging a warning message.
    case warning
    
    /// Log message type for logging an error message.
    case error
}

/// Implement the `CustomStringConvertible` protocol for the `LoggerMessageType` enum
extension LoggerMessageType : CustomStringConvertible {
    
    /// Convert a `LoggerMessageType` into a printable format.
    public var description: String {
        return ""
    }
}

extension LoggerMessageType {
    var color: TerminalColor {
        switch self {
        case .warning:
            return .yellow
        case .error:
            return .red
        default:
            return .foreground
        }
    }
}
