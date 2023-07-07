//
//  StringValueStore.swift
//  redis-pro
//
//  Created by chengpanwang on 2022/5/6.
//

import Logging
import Foundation
import SwiftyJSON
import ComposableArchitecture

private let logger = Logger(label: "string-value-store")

struct StringValueStore: ReducerProtocol {
    struct State: Equatable  {
        var redisKeyModel:RedisKeyModel?
        // 是否是完整字符串, 如果设置最大显示长度, 使用getrange命令取出部分字符串, 防止长字符串过大
        var isIntactString: Bool = true
        var stringMaxLength:Int = -1
        var length: Int = -1
        @BindingState var text:String = ""
    }
    
    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case initial
        case submit
        case submitSuccess(Bool)
        case getLength
        case getValue
        case getIntactString
        case updateLength(Int)
        case updateText(String)
        case jsonFormat
        case refresh
        case none
    }
    
    
    @Dependency(\.redisInstance) var redisInstanceModel:RedisInstanceModel
    let mainQueue: AnySchedulerOf<DispatchQueue> = .main
    
    var body: some ReducerProtocol<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
                // 初始化已设置的值
            case .initial:
                
                logger.info("value store initial...")
                return .result {
                    .success(.getLength)
                }
                
            case .getLength:
                guard let redisKeyModel = state.redisKeyModel else {
                    return .none
                }
                if redisKeyModel.isNew {
                    state.text = ""
                    return .none
                }
                let key = redisKeyModel.key
                
                return .task {
                    let r = await redisInstanceModel.getClient().strLen(key)
                    return .updateLength(r)
                }
                .receive(on: mainQueue)
                .eraseToEffect()
                
            case .getValue:
                guard let redisKeyModel = state.redisKeyModel else {
                    return .none
                }
                if redisKeyModel.isNew {
                    state.text = ""
                    return .none
                }
                
                let stringMaxLength = state.stringMaxLength
                let isIntactString = state.isIntactString
                
                let key = redisKeyModel.key
                return .task {
                    let r = isIntactString ? await redisInstanceModel.getClient().get(key) : await redisInstanceModel.getClient().getRange(key, end: stringMaxLength)
                    return .updateText(r)
                }
                .receive(on: mainQueue)
                .eraseToEffect()
                
            case .getIntactString:
                state.isIntactString = true
                return .result {
                    .success(.getValue)
                }
                
            case .submit:
                guard let redisKeyModel = state.redisKeyModel else {
                    return .none
                }
                
                let key = redisKeyModel.key
                let isNew = redisKeyModel.isNew
                let text = state.text
                return .task {
                    await redisInstanceModel.getClient().set(key, value: text)
                    return .submitSuccess(isNew)
                }
                .receive(on: mainQueue)
                .eraseToEffect()
                
            case .submitSuccess:
                return .none
                
            case let .updateLength(length):
                state.length = length
                let stringMaxLength = RedisDefaults.getStringMaxLength()
                
                state.stringMaxLength = stringMaxLength
                state.isIntactString = stringMaxLength == -1 || length <= stringMaxLength
                return .result {
                    .success(.getValue)
                }
                
            case let .updateText(text):
                state.text = text
                return .none
                
            case .jsonFormat:
                if state.text.count < 2 {
                    
                    Messages.show(BizError("Format json error"))
                    return .none
                }
                let jsonObj = JSON(parseJSON: state.text)
                if jsonObj == JSON.null {
                    Messages.show(BizError("Format json error"))
                    return .none
                }
                if let string = jsonObj.rawString() {
                    state.text = string
                }
                return .none
                
            case .refresh:
                return .result {
                    .success(.getLength)
                }
            case .none:
                return .none
            }
        }
    }
}
