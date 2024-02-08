//
//  VersionModel.swift
//  redis-pro
//
//  Created by chengpan on 2024/1/28.
//

import Foundation

struct VersionModel: Decodable {
    var latestVersionNum: Int = 0
    var latestVersion: String = ""
    var updateType: String = ""
    var releaseNotes: String = ""
    
    enum CodingKeys: String, CodingKey {
        case latestVersionNum, latestVersion, updateType, releaseNotes
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
    
        latestVersionNum = try container.decodeIfPresent(Int.self, forKey: .latestVersionNum) ?? 0
        latestVersion = try container.decodeIfPresent(String.self, forKey: .latestVersion) ?? ""
        updateType = try container.decodeIfPresent(String.self, forKey: .updateType) ?? ""
        releaseNotes = try container.decodeIfPresent(String.self, forKey: .releaseNotes) ?? ""
    }
}
