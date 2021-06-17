//
//  LogFormatter.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/6/17.
//

import Foundation
import Puppy

class LogFormatter: LogFormattable {
    func formatMessage(_ level: LogLevel, message: String, tag: String, function: String,
                       file: String, line: UInt, swiftLogInfo: [String : String],
                       label: String, date: Date, threadID: UInt64) -> String {
        let date = dateFormatter(date, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSSZ")
        let file = shortFileName(file)
        return "\(date) [\(level.emoji) \(level)] \(file)#L.\(line) \(function) \(message)"
    }
}

class PuppyFileRotationDelegate: FileRotationLoggerDeletate {
    func fileRotationLogger(_ fileRotationLogger: FileRotationLogger,
                            didArchiveFileURL: URL, toFileURL: URL) {
        print("puppy didArchiveFileURL: \(didArchiveFileURL), to file URL: \(toFileURL)")
    }
    func fileRotationLogger(_ fileRotationLogger: FileRotationLogger,
                            didRemoveArchivedFileURL: URL) {
        print("puppy didRemoveArchivedFileURL: \(didRemoveArchivedFileURL)")
    }
}
