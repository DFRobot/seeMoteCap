//
//  ReplicaPlacementController.swift
//  seeMoteViewer
//
//  Copyright © 2026 seeMote. All rights reserved.
//

import Foundation

/// 管理数字复制品放置与清除信号。
///
/// 信号流按需创建；当消费端（`for await`）因沉浸空间关闭而终止后，
/// 下次读取 `signal` 会自动生成新的流，确保重新进入沉浸空间仍能触发操作。
@MainActor
final class ReplicaPlacementController {
    private let lock = NSLock()
    private var _signal: AsyncStream<Void>?
    private var continuation: AsyncStream<Void>.Continuation?
    private var _clearSignal: AsyncStream<Void>?
    private var clearContinuation: AsyncStream<Void>.Continuation?

    var signal: AsyncStream<Void> {
        lock.lock()
        defer { lock.unlock() }

        if let existing = _signal {
            return existing
        }

        let (stream, newContinuation) = AsyncStream.makeStream(
            of: Void.self,
            bufferingPolicy: .bufferingNewest(1)
        )
        newContinuation.onTermination = { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.clearStream()
            }
        }
        _signal = stream
        continuation = newContinuation
        return stream
    }

    var clearSignal: AsyncStream<Void> {
        lock.lock()
        defer { lock.unlock() }

        if let existing = _clearSignal {
            return existing
        }

        let (stream, newContinuation) = AsyncStream.makeStream(
            of: Void.self,
            bufferingPolicy: .bufferingNewest(1)
        )
        newContinuation.onTermination = { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.clearClearStream()
            }
        }
        _clearSignal = stream
        clearContinuation = newContinuation
        return stream
    }

    func trigger() {
        lock.lock()
        defer { lock.unlock() }
        continuation?.yield()
    }

    func clearReplicas() {
        lock.lock()
        defer { lock.unlock() }
        clearContinuation?.yield()
    }

    private func clearStream() {
        lock.lock()
        defer { lock.unlock() }
        _signal = nil
        continuation = nil
    }

    private func clearClearStream() {
        lock.lock()
        defer { lock.unlock() }
        _clearSignal = nil
        clearContinuation = nil
    }
}
