//
//  AppContextStoreTests.swift
//  Tests
//
//  Created by chengpan on 2023/8/5.
//

@testable import redis_pro
import Foundation
import XCTest
import ComposableArchitecture

@MainActor
class AppContextStoreTests: StoreBaseTests {
    func testShow() async {
        let store = TestStore(initialState: AppContextStore.State()) {
            AppContextStore()
        } withDependencies: {
            $0.redisInstance = redisInstance
            $0.redisClient = redisClient
        }
        
        await store.send(.show) {
            $0.loading = true
            $0.loadingCount = 1
        }
    }
}
