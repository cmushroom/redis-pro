//
//  SettingsStore.swift
//  redis-pro
//
//  Created by chengpan on 2022/5/2.
//

import Logging
import Foundation
import SwiftUI
import ComposableArchitecture

private let logger = Logger(label: "settings-store")
private let userDefaults = UserDefaults.standard

struct SettingsStore: ReducerProtocol {
    struct State: Equatable {
        var colorSchemeValue:String?
        var defaultFavorite:String = "last"
        var stringMaxLength:Int = Const.DEFAULT_STRING_MAX_LENGTH
        var keepalive:Int = 30
        var redisModels: [RedisModel] = []
    }

    enum Action: Equatable {
        case initial
        case setColorScheme(String)
        case setDefaultFavorite(String)
        case setStringMaxLength(Int)
        case setKeepalive(Int)
    }
    
    var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
            // 初始化已设置的值
            case .initial:
                logger.info("settings store initial...")
                state.colorSchemeValue = UserDefaults.standard.string(forKey: UserDefaulsKeysEnum.AppColorScheme.rawValue) ?? ColorSchemeEnum.SYSTEM.rawValue
                
                let stringMaxLength:String? = UserDefaults.standard.string(forKey: UserDefaulsKeysEnum.AppStringMaxLength.rawValue)
                if let stringMaxLength = stringMaxLength {
                    state.stringMaxLength = Int(stringMaxLength) ?? Const.DEFAULT_STRING_MAX_LENGTH
                } else {
                    state.stringMaxLength = Const.DEFAULT_STRING_MAX_LENGTH
                }
                
                state.defaultFavorite = UserDefaults.standard.string(forKey: UserDefaulsKeysEnum.RedisFavoriteDefaultSelectType.rawValue) ?? RedisFavoriteDefaultSelectTypeEnum.LAST.rawValue
                
                
                state.redisModels = RedisDefaults.getAll()
                return .none
            // 显示模式设置， 明亮，暗黑，系统
            case let .setColorScheme(colorSchemeValue):
                logger.info("upate color scheme action, \(colorSchemeValue)")
                state.colorSchemeValue = colorSchemeValue
                UserDefaults.standard.set(colorSchemeValue, forKey: UserDefaulsKeysEnum.AppColorScheme.rawValue)
                
                if colorSchemeValue == ColorSchemeEnum.SYSTEM.rawValue {
                    NSApp.appearance = nil
                } else {
                    NSApp.appearance = NSAppearance(named:  colorSchemeValue == ColorSchemeEnum.DARK.rawValue ? .darkAqua : .aqua)
                }
                return .none
            // 默认选中设置
            case let .setDefaultFavorite(defaultFavorite):
                logger.info("upate default favorite action, \(defaultFavorite)")
                
                state.defaultFavorite = defaultFavorite
                UserDefaults.standard.set(defaultFavorite, forKey: UserDefaulsKeysEnum.RedisFavoriteDefaultSelectType.rawValue)
                return .none
                
            case let .setStringMaxLength(stringMaxLength):
                logger.info("set stringMaxLength action, \(stringMaxLength)")
                
                state.stringMaxLength = stringMaxLength
                UserDefaults.standard.set(stringMaxLength, forKey: UserDefaulsKeysEnum.AppStringMaxLength.rawValue)
                return .none
                
            case let .setKeepalive(keepalive):
                logger.info("set keepalive second action, \(keepalive)")
                
                state.keepalive = keepalive
                UserDefaults.standard.set(keepalive, forKey: UserDefaulsKeysEnum.AppKeepalive.rawValue)
                return .none
            }
        }
    }
}
