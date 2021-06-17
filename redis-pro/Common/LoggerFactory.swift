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
    var puppy = Puppy.default
    
    init() {
        let console = ConsoleLogger("com.cmushroom.redis-pro.console")
        console.format = LogFormatter()
        
        let delegate = PuppyFileRotationDelegate()
        
        let fileURL = URL(fileURLWithPath: "./redis-pro.log").absoluteURL
        let fileRotation = try! FileRotationLogger("com.cmushroom.redis-pro.file",
                                                   fileURL: fileURL)
        fileRotation.maxFileSize = 10 * 1024 * 1024
        fileRotation.maxArchivedFilesCount = 5
        fileRotation.delegate = delegate
        fileRotation.format = LogFormatter()
        
//        let puppy = Puppy.default
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
