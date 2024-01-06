//
//  RedisKeysStoreTest.swift
//  Tests
//
//  Created by chengpan on 2024/1/1.
//

@testable import redis_pro
import Foundation
import XCTest
import ComposableArchitecture

@MainActor
class KeysDelStoreTests: StoreBaseTests {
    func testBasics() async {
        let store = TestStore(initialState: RedisKeysStore.State()) {
            RedisKeysStore()
        } withDependencies: {
            $0.redisClient = redisClient
        }
        
        
        await redisClient.set("__keys_del_str_1", value: UUID.init().uuidString)
        await redisClient.set("__keys_del_str_2", value: UUID.init().uuidString)
        await redisClient.set("__keys_del_str_3", value: UUID.init().uuidString)
        await redisClient.set("__keys_del_str_4", value: UUID.init().uuidString)
        await redisClient.set("__keys_del_str_5", value: UUID.init().uuidString)
        await store.send(.search("__keys_del_str_*")) {
            $0.pageState = PageStore.State()
        }
        
        XCTAssertEqual(store.state.tableState.datasource.count, 5)
    }
}
