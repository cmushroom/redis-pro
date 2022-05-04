//
//  BaseState.swift
//  redis-pro
//
//  Created by chengpan on 2022/5/3.
//

import Foundation

//@dynamicMemberLookup
protocol BaseState: Equatable {
    var loading: Bool {
        get
        set
    }
    var appAlertState: AppAlertState {get set}
    var loadingState: LoadingState {get set}
}
