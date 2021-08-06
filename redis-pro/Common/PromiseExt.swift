//
//  PromiseExt.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/6/1.
//

import Foundation
import PromiseKit

extension Promise {
    static func reject() -> Promise<T> {
        return Promise<T>(error: BizError("promise reject"))
    }
    
}
