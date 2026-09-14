//
//  CancellableTask.swift
//  seeMoteViewer
//
//  Copyright © 2026 seeMote. All rights reserved.
//

import Foundation

/// 非隔离的可取消任务包装。
///
/// 用于在 `@MainActor @Observable` 类的 `deinit` 中安全取消任务，同时避免
/// `nonisolated(unsafe)` 警告。所有读写通过 `NSLock` 串行化；`Task.cancel()`
/// 与可选值赋值本身可在任意线程安全调用。
final class CancellableTask: @unchecked Sendable {
    private let lock = NSLock()
    private var task: Task<Void, Never>?

    func set(_ newTask: Task<Void, Never>?) {
        lock.lock()
        defer { lock.unlock() }
        task?.cancel()
        task = newTask
    }

    func cancel() {
        set(nil)
    }

    deinit {
        cancel()
    }
}
