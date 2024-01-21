
#  Redis Pro

[English](./README.md) | 简体中文 

![Swift5.0+](https://img.shields.io/badge/Swift-5.0%2B-orange.svg?style=flat)
[![release](https://img.shields.io/github/v/release/cmushroom/redis-pro?include_prereleases)](https://github.com/cmushroom/redis-pro/releases)
![platforms](https://img.shields.io/badge/Platforms-macOS%20-orange.svg?style=flat)
[![Gitter](https://badges.gitter.im/redis-pro/community.svg)](https://gitter.im/redis-pro/community?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)

## 简介
* redis-pro 是一款 redis 轻量客户端管理工具， 采用SwiftUI 编写
* 开发过程中借鉴了 [Sequel-Ace](https://github.com/Sequel-Ace/Sequel-Ace)! 和阿里云DMS，Sequel-Ace (前身 Sequel-Pro) 是一个简洁易用的小众 mysql桌面客户端

## 安装
* 到release页面下载安装
[下载地址](https://github.com/cmushroom/redis-pro/releases)
* homebrew
    ```
    brew install redis-pro
    ```




## 平台
目前只支持 macos (Intel, Apple Silicon) 平台,  后续考虑支持 ipad os

## 功能计划(暂定)
- [x] client list and kill 
- [x] homebrew install
- [x] slow log
- [x] redis config update
- [x] ssh login
- [x] favorite delete confirm
- [x] TCA
- [x] delete batch
- [ ] terminal
- [ ] ipad os support
- [ ] ssh key support

    

## 版本要求
* macos:  >= 11.0
* redis: 3.x¹ ... 6.x

## 依赖
* RediStack 采用swiftNIO 编写的redis client
* swift-log swift 日志框架, 是上层框架， 需要具体的实现
* Puppy 日志实现, 滚动写入到日志文件
* SwiftyJSON json 转换



## 应用截图
登录页
<img width="1124" alt="0" src="https://user-images.githubusercontent.com/2920167/125376590-ec6fb500-e3bd-11eb-8f6b-140c32578e8c.png">

首页
<img width="1124" alt="1" src="https://user-images.githubusercontent.com/2920167/125376643-0e693780-e3be-11eb-92fa-9c13dcc26f78.png">

设置
<img width="1128" alt="2" src="https://user-images.githubusercontent.com/2920167/125376658-15904580-e3be-11eb-94cf-8590a550ea1a.png">

Info
<img width="1124" alt="3" src="https://user-images.githubusercontent.com/2920167/125376733-39538b80-e3be-11eb-896d-72cacb469540.png">

Clients
<img width="1124" alt="4" src="https://user-images.githubusercontent.com/2920167/125376767-4a9c9800-e3be-11eb-84b3-33c2c1c846fc.png">


暗黑模式
<img width="1124" alt="5" src="https://user-images.githubusercontent.com/2920167/125376789-538d6980-e3be-11eb-9267-6a451597f983.png">
<img width="1124" alt="5" src="https://user-images.githubusercontent.com/2920167/125376778-4f614c00-e3be-11eb-8c11-7195e4cdb665.png">


## FAQ
* keys 分页数量不匹配
redis scan 命令特性决定， COUNT 选项的作用就是让用户告知迭代命令， 在每次迭代中应该从数据集里返回多少元素。虽然 COUNT 选项只是对增量式迭代命令的一种提示（hint）， 但是在大多数情况下， 这种提示都是有效的。少数情况会发生返回数量与COUNT不一致的情况， 多数发生在keys数量不多， 与页大小差距不大的情况
