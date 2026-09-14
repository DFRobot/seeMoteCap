//
//  HapticController.swift
//  seeMoteViewer
//
//  Copyright © 2026 seeMote. All rights reserved.
//

@unsafe @preconcurrency import GameController
import CoreHaptics
import Observation
import os.log

/// 管理 seeMote 配件的触觉反馈。
///
/// `CHHapticEngine` 会在 App 进入后台、音频会话中断等场景下被系统停止。
/// 本类在播放前主动确保引擎处于运行状态，避免缓存引用与实际状态不一致导致无震动。
@MainActor
@Observable
final class HapticController {
    private enum Constants {
        static let intensity: Float = 1.0
        static let sharpness: Float = 0.5
        static let pulseInterval: TimeInterval = 0.5
    }

    private let logger = Logger(category: "HapticController")

    /// 用于在引擎被释放后重新创建。
    /// 使用弱引用避免 `HapticController` 反向延长配件生命周期。
    private weak var accessory: GCSpatialAccessory?
    private var engine: CHHapticEngine?

    /// 当前配件是否支持触觉反馈。
    ///
    /// 只有成功创建并启动过引擎才认为支持。
    var supportsHaptics: Bool {
        engine != nil
    }

    /// 为指定配件初始化触觉引擎。
    init(accessory: GCSpatialAccessory) async {
        self.accessory = accessory
        await prepare()
    }

    /// 准备引擎：创建并启动；若已缓存则重新启动以确保处于 running 状态。
    @discardableResult
    func prepare() async -> Bool {
        if let engine {
            do {
                try await engine.start()
                logger.info("Haptic engine prepared.")
                return true
            } catch {
                logger.error("Failed to restart cached haptic engine: \(error)")
                self.engine = nil
            }
        }

        return await setupEngine()
    }

    /// 创建并启动触觉引擎，同时注册系统生命周期回调。
    private func setupEngine() async -> Bool {
        guard let accessory,
              let haptics = accessory.haptics,
              let engine = haptics.createEngine(withLocality: .default) else {
            logger.info("Accessory does not support haptics.")
            self.engine = nil
            return false
        }

        // 当系统停止引擎时（例如所有窗口关闭、App 进入后台），
        // 仅记录日志；实际恢复交给播放路径的 prepare() 处理。
        engine.stoppedHandler = { [weak self] reason in
            Task { @MainActor [weak self] in
                guard let self else { return }
                logger.info("Haptic engine stopped: \(String(describing: reason))")
            }
        }

        engine.resetHandler = { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                logger.info("Haptic engine requested reset.")
            }
        }

        do {
            try await engine.start()
            self.engine = engine
            logger.info("Haptic engine started.")
            return true
        } catch {
            logger.error("Failed to start haptic engine: \(error)")
            self.engine = nil
            return false
        }
    }

    /// 播放触觉反馈。
    ///
    /// - Parameter multiPulse: 为 true 时播放三个连续脉冲，否则播放单个脉冲。
    func play(multiPulse: Bool = false) async {
        logger.info("Play haptics requested (multiPulse: \(multiPulse)).")

        guard await prepare() else {
            logger.error("Haptic engine unavailable, cannot play.")
            return
        }

        do {
            try playPattern(multiPulse: multiPulse)
            logger.info("Haptic pattern started successfully.")
        } catch {
            logger.error("Failed to play haptics: \(error)")
        }
    }

    private func playPattern(multiPulse: Bool) throws {
        guard let engine else {
            throw HapticError.noEngine
        }

        let events = makeEvents(multiPulse: multiPulse)
        let pattern = try CHHapticPattern(events: events, parameters: [])
        let player = try engine.makePlayer(with: pattern)
        try player.start(atTime: CHHapticTimeImmediate)
    }

    /// 内部错误类型，用于在播放路径中传播引擎不可用的情况。
    private enum HapticError: Error {
        case noEngine
    }

    private func makeEvents(multiPulse: Bool) -> [CHHapticEvent] {
        var events = [makePulseEvent(at: 0.0)]
        if multiPulse {
            events.append(makePulseEvent(at: Constants.pulseInterval))
            events.append(makePulseEvent(at: Constants.pulseInterval * 2))
        }
        return events
    }

    private func makePulseEvent(at relativeTime: TimeInterval) -> CHHapticEvent {
        CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: Constants.intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: Constants.sharpness)
            ],
            relativeTime: relativeTime
        )
    }
}
