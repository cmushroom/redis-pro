//
//  VersionManager.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/6/9.
//

import Foundation
import SwiftUI
import Logging

struct VersionManager {
    let logger = Logger(label: "version-manager")
    let checkUpdateUrl:String = "https://gitee.com/chengpan168_admin/redis-pro/raw/dev/.version"
    
    func checkUpdate(isNoUpgradeHint:Bool = false) -> Void {
        let currentVersionNum = Bundle.main.infoDictionary?["CFBundleVersion"]
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"]
        logger.info("check app update start, current version num: \(currentVersionNum ?? ""), version: \(currentVersion ?? "")")
        
        if currentVersionNum == nil {
            return
        }
        
        if let url = URL(string: checkUpdateUrl) {
            do {
                let contents = try String(contentsOf: url)
                logger.info("get new version result: \(contents)")
                if contents.count < 2 {
                    return
                }
                
                let versionInfo = try JSONDecoder().decode(VersionModel.self, from: contents.data(using: .utf8)!)
                
                let currentVersionInt = Int("\(currentVersionNum ?? 0)") ?? 0
                logger.info("compare latest version, latest version info: \(versionInfo), current version: \(currentVersionInt)")
                if versionInfo.latestVersionNum > currentVersionInt {
                    logger.info("get new version success, please update!")
                    
                    // 提示升级
                    if versionInfo.updateType == "hint" {
                        Task {
                            let r = await Messages.confirmAsync("New version \(versionInfo.latestVersion) is available", message: versionInfo.releaseNotes,
                                                                primaryButton: "Upgrade")
                            
                            if r {
                                if let url = URL(string: Const.RELEASE_URL) {
                                    NSWorkspace.shared.open(url)
                                }
                            }
                        }
                    }
                    // 强制升级
                    else if versionInfo.updateType == "force" {
                        
                    }
                } else {
                    if isNoUpgradeHint {
                        Messages.show("Current version \(currentVersion ?? "") is latest!")
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
