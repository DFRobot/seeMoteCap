//
//  AccessoryConnectionManager.swift
//  seeMoteViewer
//
//  Copyright © 2026 seeMote. All rights reserved.
//

import Foundation
@unsafe @preconcurrency import GameController

/// 管理 `GCSpatialAccessory` 的连接与断开。
@MainActor
@Observable
final class AccessoryConnectionManager {
    private(set) var connectedDevice: GCSpatialAccessory? {
        didSet {
            guard connectedDevice != oldValue else { return }
            onDeviceChanged?(connectedDevice)
        }
    }

    var isAccessoryConnected: Bool { connectedDevice != nil }

    private let initializationTask = CancellableTask()

    /// 设备变化回调
    var onDeviceChanged: ((GCSpatialAccessory?) -> Void)?

    init() {
        initializationTask.set(Task { [weak self] in
            await self?.observeConnections()
        })
    }

    private func observeConnections() async {
        if let accessory = GCSpatialAccessory.spatialAccessories.first {
            connectedDevice = accessory
        }

        await withTaskGroup(of: Void.self) { group in
            group.addTask { [weak self] in
                for await notification in NotificationCenter.default.notifications(named: .GCSpatialAccessoryDidConnect) {
                    guard let accessory = notification.object as? GCSpatialAccessory else { continue }
                    await MainActor.run {
                        guard let self else { return }
                        self.connectedDevice = accessory
                    }
                }
            }
            group.addTask { [weak self] in
                for await notification in NotificationCenter.default.notifications(named: .GCSpatialAccessoryDidDisconnect) {
                    guard let accessory = notification.object as? GCSpatialAccessory else { continue }
                    await MainActor.run {
                        guard let self else { return }
                        if accessory == self.connectedDevice {
                            self.connectedDevice = nil
                        }
                    }
                }
            }
        }
    }
}
