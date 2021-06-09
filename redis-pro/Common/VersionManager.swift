//
//  VersionManager.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/6/9.
//

import Foundation
import SwiftUI
import Logging
import SwiftyJSON

struct VersionManager {
    @ObservedObject var globalContext:GlobalContext
    
    let logger = Logger(label: "version-manager")
    
    func checkUpdate() -> Void {
        let version = Bundle.main.infoDictionary?["CFBundleVersion"]
        logger.info("check app update start, current version: \(String(describing: version))")
        
        if version == nil {
            return
        }
        
        if let url = URL(string: "https://gitee.com/chengpan168_admin/redis-pro/raw/dev/.version") {
            do {
                let contents = try String(contentsOf: url)
                logger.info("get new version result: \(contents)")
                if contents.count < 2 {
                    return
                }
                
                let jsonObj = JSON(parseJSON: contents)
                let latestVersion = jsonObj["currentVersion"]
                let updateType = String(describing: jsonObj["updateType"])
                
                if Int("\(latestVersion)") ?? 0 > Int("\(String(describing: version))") ?? 0 {
                    logger.info("get new version success, please update!")
                    
                    // 提示升级
                    if updateType == "hint" {
                        
                    }
                    // 强制升级
                    else if updateType == "force" {
                        
                    }
                }
                
            } catch {
                // contents could not be loaded
                logger.error("check update error: \(error)")
            }
        } else {
            // the URL was bad!
            logger.error("can not get new version from `https://gitee.com/chengpan168_admin/redis-pro/raw/dev/.version`")
        }
        
    }
}
