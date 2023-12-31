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
        
        
        await redisClient.set("__keys_del_str_1", value: UUID.init().uuidString)
        await redisClient.set("__keys_del_str_2", value: UUID.init().uuidString)
        await redisClient.set("__keys_del_str_3", value: UUID.init().uuidString)
        await store.send(.search("__keys_del_str_*")) {
            $0.pageState = PageStore.State()
        }
        
        XCTAssertEqual(store.state.tableState.datasource.count, 3)
    }
}
