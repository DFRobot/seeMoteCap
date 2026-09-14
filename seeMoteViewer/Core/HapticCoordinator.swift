//
//  HapticCoordinator.swift
//  seeMoteViewer
//
//  Copyright © 2026 seeMote. All rights reserved.
//

import Foundation
import Observation
@unsafe @preconcurrency import GameController

/// 协调 `HapticController` 的生命周期。
@MainActor
@Observable
final class HapticCoordinator {
    private(set) var hapticController: HapticController?

    var supportsHaptics: Bool {
        hapticController?.supportsHaptics == true
    }

    /// 为指定设备创建触觉控制器（若尚未创建）。
    func ensureRunning(for device: GCSpatialAccessory?) async {
        guard let device else {
            hapticController = nil
            return
        }
        if hapticController == nil {
            hapticController = await HapticController(accessory: device)
        }
    }

    /// 确保引擎处于 running 状态并播放触觉反馈。
    ///
    /// - Parameter multiPulse: 为 true 时播放三个连续脉冲，否则播放单个脉冲。
    func play(multiPulse: Bool = true) async {
        await hapticController?.prepare()
        await hapticController?.play(multiPulse: multiPulse)
    }

    func stop() {
        hapticController = nil
    }
}
