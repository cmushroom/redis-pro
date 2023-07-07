#  问题记录

## TCA
1. tca 监听不存在的属性值时， 会造成编译卡死， swift-frontend 内存泄漏
2. 同一个reducer被注入多次时， action方法会被多次调用，例如：
```
        Scope(state: \.redisKeysState, action: /Action.redisKeysAction) {
            RedisKeysStore(redisInstanceModel: redisInstanceModel)
        }
        Scope(state: \.redisKeysState, action: /Action.redisKeysAction) {
            RedisKeysStore(redisInstanceModel: redisInstanceModel)
        }
```
