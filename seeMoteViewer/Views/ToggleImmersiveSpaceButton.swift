//
//  ToggleImmersiveSpaceButton.swift
//  seeMoteViewer
//
//  Copyright © 2026 seeMote. All rights reserved.
//

import SwiftUI

/// 打开/关闭沉浸空间的切换开关。
struct ToggleImmersiveSpaceSwitch: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

    var body: some View {
        Toggle(isOn: immersiveSpaceBinding) {
            Text(LocalizedStringResource("toggle.immersiveSpace"))
        }
        .disabled(appState.sceneState.immersiveSpaceState == .inTransition || appState.accessoryTracker.previewEntity == nil)
    }

    /// 将沉浸空间状态映射为 Bool 绑定。
    ///
    /// 处于转换状态时禁用 Toggle，状态本身不会停留在 `.inTransition`，
    /// 因此绑定值只反映 `.open` / `.closed`。
    private var immersiveSpaceBinding: Binding<Bool> {
        Binding(
            get: { appState.sceneState.immersiveSpaceState == .open },
            set: { isOn in
                toggleImmersiveSpace(targetOpen: isOn)
            }
        )
    }

    /// 根据目标状态打开或关闭沉浸空间。
    private func toggleImmersiveSpace(targetOpen: Bool) {
        let currentState = appState.sceneState.immersiveSpaceState

        // 仅在状态与目标不一致时执行；转换中已被 disabled 拦截。
        guard currentState != (targetOpen ? .open : .closed) else { return }

        if targetOpen {
            guard appState.sceneState.enterTransition() else { return }
            Task {
                let result = await openImmersiveSpace(id: AppConfiguration.immersiveSpaceID)
                appState.sceneState.exitTransition(opened: result == .opened)
            }
        } else {
            guard appState.sceneState.enterTransition() else { return }
            Task {
                await dismissImmersiveSpace()
                appState.sceneState.exitTransition(opened: false)
            }
        }
    }
}
