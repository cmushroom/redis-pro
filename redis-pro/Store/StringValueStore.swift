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
struct StringValueState: Equatable {
    var redisKeyModel:RedisKeyModel?
    // 是否是完整字符串, 如果设置最大显示长度, 使用getrange命令取出部分字符串, 防止长字符串过大
    var isIntactString: Bool = true
    var stringMaxLength:Int = -1
    var length: Int = -1
    @BindableState var text:String = ""
    
    init() {
        logger.info("string value state init ...")
    }
}

enum StringValueAction:BindableAction, Equatable {
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
    case binding(BindingAction<StringValueState>)
}

struct StringValueEnvironment {
    var redisInstanceModel:RedisInstanceModel
    var mainQueue: AnySchedulerOf<DispatchQueue> = .main
}

let stringValueReducer = Reducer<StringValueState, StringValueAction, StringValueEnvironment>.combine(
    Reducer<StringValueState, StringValueAction, StringValueEnvironment> {
        state, action, env in
        switch action {
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
                let r = await env.redisInstanceModel.getClient().strLen(key)
                return .updateLength(r)
            }
            .receive(on: env.mainQueue)
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
                let r = isIntactString ? await env.redisInstanceModel.getClient().get(key) : await env.redisInstanceModel.getClient().getRange(key, end: stringMaxLength)
                return .updateText(r)
            }
            .receive(on: env.mainQueue)
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
                await env.redisInstanceModel.getClient().set(key, value: text)
                return .submitSuccess(isNew)
            }
            .receive(on: env.mainQueue)
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
        case .binding:
            return .none
        }
    }
).binding().debug()
