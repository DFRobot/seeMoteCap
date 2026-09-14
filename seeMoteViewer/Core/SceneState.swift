//
//  SceneState.swift
//  seeMoteViewer
//
//  Copyright © 2026 seeMote. All rights reserved.
//

import SwiftUI

/// 场景状态（沉浸空间）。
@MainActor
@Observable
final class SceneState {
    /// 沉浸空间当前状态
    var immersiveSpaceState: ImmersiveSpaceState = .closed

    /// 尝试进入状态转换；如果已经在转换中则返回 false。
    @discardableResult
    func enterTransition() -> Bool {
        guard immersiveSpaceState != .inTransition else { return false }
        immersiveSpaceState = .inTransition
        return true
    }

    /// 退出状态转换，根据结果设置最终状态。
    func exitTransition(opened: Bool) {
        immersiveSpaceState = opened ? .open : .closed
    }
}

/// 沉浸空间状态。
enum ImmersiveSpaceState: String, Equatable {
    case closed
    case inTransition
    case open
}
