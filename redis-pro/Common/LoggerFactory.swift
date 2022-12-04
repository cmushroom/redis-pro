//
//  LoggerFactory.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/6/17.
//

import Foundation
import Logging
import Puppy

class LoggerFactory {
    var puppy = Puppy.init()
    
    init() {
        let console = ConsoleLogger("com.cmushroom.redis-pro.console", logFormat: LogFormatter())

        let fileURL = URL(fileURLWithPath: "./redis-pro.log").absoluteURL
        let fileRotation = try! FileRotationLogger("com.cmushroom.redis-pro.file",
                                                   fileURL: fileURL,
                                                   rotationConfig: RotationConfig(
                                                    maxFileSize: 10 * 1024 * 1024,
                                                    maxArchivedFilesCount: 5
                                                   ))
        self.puppy.add(console)
        self.puppy.add(fileRotation)
        
        self.puppy.info("init logger complete...")
    }
    
    func setUp() -> Void {
        LoggingSystem.bootstrap {
            var handler = PuppyLogHandler(label: $0, puppy: self.puppy)
            // Set the logging level.
            handler.logLevel = .info
            return handler
        }

    }
}
