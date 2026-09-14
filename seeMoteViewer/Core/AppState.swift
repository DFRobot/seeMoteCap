//
//  AppState.swift
//  seeMoteViewer
//
//  Copyright © 2026 seeMote. All rights reserved.
//

import Foundation
import SwiftUI

/// 应用全局可观察状态容器。
@MainActor
@Observable
final class AppState {
    /// 场景状态
    let sceneState = SceneState()

    /// 语言管理
    let localeManager = LocaleManager()

    /// 配件追踪器
    let accessoryTracker = AccessoryTracker()
}
