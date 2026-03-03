//
//  ShareStateExt.swift
//  redis-pro
//
//  Created by chengpanwang on 2025/2/5.
//

import Foundation
import ComposableArchitecture

extension IdentifiedArrayOf where ID == String, Element == RedisModel {
    func toData() -> Data? {
        try? JSONEncoder().encode(self)
    }

    static func fromData(_ data: Data) -> Self {
        (try? JSONDecoder().decode(Self.self, from: data)) ?? []
    }
}

//extension URL {
//    static let redisModels = URL(string: UserDefaulsKeysEnum.RedisFavoriteListKey.rawValue)!
//}
//
//extension SharedKey where Self == FileStorageKey<[RedisModel]> {
//  fileprivate static var redisModels: Self {
//      fileStorage(.applicationSupportDirectory.appending(component: "stats.json"))
//  }
//}
