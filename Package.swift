//
//  Package.swift
//  redis-pro
//
//  Created by chengpan on 2021/5/23.
//

import PackageDescription

let package = Package(
    name: "redis-pro",
    platforms: [
        .macOS(.v11_0)
    ],
    products: [
        .library(name: "redis-pro", targets: ["redis-pro"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://gitee.com/mirrors_apple/swift-log.git", .upToNextMinor(from: "1.4.2")),
        .package(url: "https://gitee.com/mirrors_apple/swift-service-discovery.git", .upToNextMinor(from: "1.0.0")),
        .package(url: "https://gitee.com/mirrors_apple/swift-metrics.git", .upToNextMinor(from: "2.1.1")),
        .package(url: "https://gitee.com/mirrors_apple/swift-nio.git", .upToNextMinor(from: "2.27.0")),
        .package(url: "https://gitee.com/chengpan168_admin/RediStack.git", .upToNextMinor(from: "1.1.2")),
        .package(url: "https://gitee.com/chengpan168_admin/plcrashreporter.git", .upToNextMinor(from: "1.8.0")),
        .package(url: "https://gitee.com/chengpan168_admin/appcenter-sdk-apple.git", .upToNextMinor(from: "4.1.1"))
    ],
    targets: [
        .target(
            name: "redis-pro",
            dependencies: ["swift-log", "swift-metrics", "swift-service-discovery", "swift-nio", "RediStack", "plcrashreporter", "appcenter-sdk-apple"]
        )
    ]
)
