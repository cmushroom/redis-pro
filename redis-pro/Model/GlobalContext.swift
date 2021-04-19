//
//  GlobalContext.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/15.
//

import Foundation

class GlobalContext:ObservableObject {
    @Published var alertVisible:Bool = false
    var message:String = ""
    var showSecondButton:Bool = false
    var primaryButtonText:String = "Ok"
    var secondButtonText:String = "Cancel"
    var primaryAction:() throws -> Void = {}
}
