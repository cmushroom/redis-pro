//
//  AppStoreTest.swift
//  Tests
//
//  Created by chengpan on 2023/8/5.
//

@testable import redis_pro
import Foundation
import XCTest
import ComposableArchitecture

@MainActor
class KeysDelStoreTests: StoreBaseTests {
    func testBasics() async {
        let store = TestStore(initialState: KeysDelStore.State()) {
            KeysDelStore()
        } withDependencies: {
            $0.redisInstance = redisInstance
            $0.redisClient = redisClient
        }
        
//        await store.send(.favoriteAction(.connectSuccess(self.redisModel))) {
//            $0.isConnect = true
//        }
    }
}
