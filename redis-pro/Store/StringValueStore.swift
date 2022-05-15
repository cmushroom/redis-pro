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
    @BindableState var text:String = ""
    
    init() {
        logger.info("string value state init ...")
    }
}

enum StringValueAction:BindableAction, Equatable {
    case initial
    case submit
    case submitSuccess(Bool)
    case getValue
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
                .success(.getValue)
            }
        
        case .getValue:
            guard let redisKeyModel = state.redisKeyModel else {
                return .none
            }
            if redisKeyModel.isNew {
                state.text = ""
                return .none
            }
            
            let key = redisKeyModel.key
            return .task {
                let r = await env.redisInstanceModel.getClient().get(key)
                return .updateText(r)
            }
            .receive(on: env.mainQueue)
            .eraseToEffect()
            
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
            
        case let .updateText(text):
            state.text = text
            return .none
            
        case .jsonFormat:
            if state.text.count < 2 {
                
                AlertUtil.show(BizError("Format json error"))
                return .none
            }
            let jsonObj = JSON(parseJSON: state.text)
            if jsonObj == JSON.null {
                AlertUtil.show(BizError("Format json error"))
                return .none
            }
            if let string = jsonObj.rawString() {
                state.text = string
            }
            return .none
         
        case .refresh:
            return .result {
                .success(.getValue)
            }
        case .none:
            return .none
        case .binding:
            return .none
        }
    }
).binding().debug()
