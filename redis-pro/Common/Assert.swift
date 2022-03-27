//
//  Assert.swift
//  redis-pro
//
//  Created by chengpan on 2022/3/27.
//

import Foundation

class Assert {
    static func isTrue(_ bool:Bool, message:String) throws -> Void  {
        if (!bool) {
            try fail(message)
        }
    }
    
    static func fail(_ message:String) throws{
        throw BizError(message: message)
    }
}
