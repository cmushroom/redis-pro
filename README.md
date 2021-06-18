#  Redis Pro

![Swift5.0+](https://img.shields.io/badge/Swift-5.0%2B-orange.svg?style=flat)
[![release](https://img.shields.io/github/v/release/cmushroom/redis-pro?include_prereleases)](https://github.com/cmushroom/redis-pro/releases)
[![license](https://img.shields.io/badge/license-Apache%202-blue)](https://github.com/cmushroom/redis-pro/blob/main/LICENSE)
![platforms](https://img.shields.io/badge/Platforms-macOS%20-orange.svg?style=flat)


## 简介
* redis-pro 是一款 redis 轻量客户端管理工具， 采用SwiftUI 编写
* 开发过程中借鉴了 [Sequel-Ace](https://github.com/Sequel-Ace/Sequel-Ace)! 和阿里云DMS，Sequel-Ace (前身 Sequel-Pro) 是一个简洁易用的小众 mysql桌面客户端

## 安装
* 到release页面下载安装
[下载地址](https://github.com/cmushroom/redis-pro/releases)



## 平台
目前只支持 macos (Intel, Apple Silicon) 平台,  后续考虑支持 ipad os， 再后期可能会支持ios

## 功能计划(暂定)
* redis config 修改
* client list and kill
* ssh 登录
* ipad os 支持
    

## 版本要求
* macos:  >= 11.0
* redis: 3.x¹ ... 6.x

## 依赖
* RediStack 采用swiftNIO 编写的redis client
* swift-log swift 日志框架, 是上层框架， 需要具体的实现
* XCGLogger 日志写入到文件使用
* SwiftyJSON json 转换
* PromiseKit 异步化操作使用， 简化callback代码



## 应用截图
登录页
![登录](https://raw.githubusercontent.com/cmushroom/redis-pro/resource/login.png)

首页
![首页](https://raw.githubusercontent.com/cmushroom/redis-pro/resource/index.png)

设置
![设置](https://raw.githubusercontent.com/cmushroom/redis-pro/resource/settings.png)

Info
![设置](https://raw.githubusercontent.com/cmushroom/redis-pro/resource/info.png)

暗黑模式
![设置](https://raw.githubusercontent.com/cmushroom/redis-pro/resource/dark.png)


** FAQ
* keys 分页数量不匹配
redis scan 命令特性决定， COUNT 选项的作用就是让用户告知迭代命令， 在每次迭代中应该从数据集里返回多少元素。虽然 COUNT 选项只是对增量式迭代命令的一种提示（hint）， 但是在大多数情况下， 这种提示都是有效的。少数情况会发生返回数量与COUNT不一致的情况， 多数发生在keys数量不多， 与页大小差距不大的情况
