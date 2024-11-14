//
//  NetworkMonitor.swift
//  redis-pro
//
//  Created by chengpan on 2024/1/13.
//

import Logging
import Foundation
import Network

class NetworkMonitor {
    private let logger = Logger(label: "network-monitor")
    private var monitor: NWPathMonitor?

    init() {
        monitor = NWPathMonitor()
    }

    func startMonitoring(_ callback: @escaping (Bool) async -> Void) {
        monitor?.pathUpdateHandler = { path in
            if path.usesInterfaceType(.wifi) {
                self.logger.info("WiFi status changed")
                if path.status == .satisfied {
                    self.logger.info("WiFi is connected")
                    Task {
                        await callback(true)
                    }
                } else {
                    self.logger.info("WiFi is not connected")
                    Task {
                        await callback(false)
                    }
                }
            }
        }

        let queue = DispatchQueue(label: "WiFiMonitorQueue")
        monitor?.start(queue: queue)
    }

    func stopMonitoring() {
        monitor?.cancel()
    }
}
