//
//  AppContext.swift
//  redis-pro
//
//  Created by chengpan on 2023/7/4.
//

import Foundation
import Combine
import ComposableArchitecture

struct AppContext {
//    let loading: PassthroughSubject<Bool, Never> = .init()
    var loading: () -> Int
    var play: (Int) -> Effect<FavoriteStore.Action, Never>
//    var loading: () -> Bool
//    var setLoading: (Bool) -> Effect<Never, Never>
    
    //    private var _loading = false
    //    private var _loadingCount = 0
    //
    //    var loading: Bool {
    //        get {
    //            _loading
    //        }
    //        set (newValue) {
    //            _loading = newValue
    //        }
    //    }
}
//extension AppContext {
//    static var live: Self = AppContext()
//}

extension AppContext {
    static var live: Self {
        var loading: Int = 0
        return Self(
            loading: { loading },
            play: { newId in
                print("sfsafd: \(newId)")
                    return .fireAndForget {
                        print("fsafsdfdsfsdfdsf \(newId)")
                        return loading = newId
        
                    }
            }
        )
    }
}
