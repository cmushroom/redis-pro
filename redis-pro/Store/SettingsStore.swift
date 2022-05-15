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
struct SettingsState: Equatable {
    var colorSchemeValue:String?
    var defaultFavorite:String = "last"
    var redisModels: [RedisModel] = []
    
    init() {
        logger.info("settings state init ...")
    }
}

enum SettingsAction:Equatable {
    case initial
    case updateColorScheme(String)
    case updateDefaultFavorite(String)
}

struct SettingsEnvironment {
}

let settingsReducer = Reducer<SettingsState, SettingsAction, SettingsEnvironment>.combine(
    Reducer<SettingsState, SettingsAction, SettingsEnvironment> {
        state, action, _ in
        switch action {
        // 初始化已设置的值
        case .initial:
            logger.info("settings store initial...")
            state.colorSchemeValue = UserDefaults.standard.string(forKey: UserDefaulsKeysEnum.AppColorScheme.rawValue) ?? ColorSchemeEnum.SYSTEM.rawValue
            state.defaultFavorite = UserDefaults.standard.string(forKey: UserDefaulsKeysEnum.RedisFavoriteDefaultSelectType.rawValue) ?? RedisFavoriteDefaultSelectTypeEnum.LAST.rawValue
            state.redisModels = RedisDefaults.getAll()
            return .none
        // 显示模式设置， 明亮，暗黑，系统
        case let .updateColorScheme(colorSchemeValue):
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
        case let .updateDefaultFavorite(defaultFavorite):
            logger.info("upate default favorite action, \(defaultFavorite)")
            
            state.defaultFavorite = defaultFavorite
            UserDefaults.standard.set(defaultFavorite, forKey: UserDefaulsKeysEnum.RedisFavoriteDefaultSelectType.rawValue)
            return .none
        }
    }
).debug()

