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
    
    func checkUpdate(isNoUpgradeHint:Bool = false) -> Void {
        let currentVersionNum = Bundle.main.infoDictionary?["CFBundleVersion"]
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"]
        logger.info("check app update start, current version num: \(currentVersionNum ?? ""), version: \(currentVersion ?? "")")
        
        if currentVersionNum == nil {
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
                let latestVersionNum = jsonObj["latestVersionNum"]
                let latestVersion = String(describing: jsonObj["latestVersion"])
                let updateType = String(describing: jsonObj["updateType"])
                let releaseNotes = String(describing: jsonObj["releaseNotes"])
                
                let currentVersionInt = Int("\(currentVersionNum ?? 0)") ?? 0
                let latestVersionInt = Int("\(latestVersionNum)") ?? 0
                logger.info("compare latest version, latest version: \(latestVersionInt), current version: \(currentVersionInt)")
                if latestVersionInt > currentVersionInt {
                    logger.info("get new version success, please update!")
                    
                    // 提示升级
                    if updateType == "hint" {
                        globalContext.alertVisible = true
                        globalContext.alertTitle = "New version \(latestVersion) is available"
                        globalContext.alertMessage = releaseNotes
                        globalContext.primaryButtonText = "Upgrade"
                        globalContext.showSecondButton = true
                        globalContext.primaryAction = {
                            if let url = URL(string: Constants.RELEASE_URL) {
                                NSWorkspace.shared.open(url)
                            }
                        }
                    }
                    // 强制升级
                    else if updateType == "force" {
                        
                    }
                } else {
                    if isNoUpgradeHint {
                        globalContext.alertVisible = true
                        globalContext.alertTitle = "Current version \(currentVersion ?? "") is latest!"
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
