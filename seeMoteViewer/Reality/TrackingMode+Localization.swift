//
//  TrackingMode+Localization.swift
//  seeMoteViewer
//
//  Copyright © 2026 seeMote. All rights reserved.
//

import ARKit
import Foundation
import RealityKit

extension AnchoringComponent.AccessoryLocation {
    /// 本地化显示名称。
    ///
    /// 系统提供的 `name` 可能为 nil 或非用户可读字符串，
    /// 对于已知位置（如 `.origin`）使用明确的本地化键，
    /// 其余位置优先回退到系统名称，最后使用 "Unknown"。
    var localizedName: LocalizedStringResource {
        if self == .origin {
            return LocalizedStringResource("accessoryLocation.origin")
        }
        if let name {
            return LocalizedStringResource(stringLiteral: name)
        }
        return LocalizedStringResource("Unknown")
    }
}

extension AnchoringComponent.TrackingMode {
    /// 本地化显示名称
    var localizedLabel: LocalizedStringResource {
        switch self {
        case .continuous:
            return LocalizedStringResource("trackingMode.continuous")
        case .predicted:
            return LocalizedStringResource("trackingMode.predicted")
        default:
            return LocalizedStringResource("trackingMode.unknown")
        }
    }
}

extension ARKitSession.AuthorizationStatus {
    var localizedDescription: LocalizedStringResource {
        switch self {
        case .notDetermined:
            return LocalizedStringResource("authorizationStatus.notDetermined")
        case .allowed:
            return LocalizedStringResource("authorizationStatus.allowed")
        case .denied:
            return LocalizedStringResource("authorizationStatus.denied")
        @unknown default:
            return LocalizedStringResource("authorizationStatus.unknown")
        }
    }
}

extension DataProviderState {
    var localizedDescription: LocalizedStringResource {
        switch self {
        case .initialized:
            return LocalizedStringResource("providerState.initialized")
        case .running:
            return LocalizedStringResource("providerState.running")
        case .paused:
            return LocalizedStringResource("providerState.paused")
        case .stopped:
            return LocalizedStringResource("providerState.stopped")
        @unknown default:
            return LocalizedStringResource("providerState.unknown")
        }
    }
}

extension AccessoryAnchor.TrackingState {
    var localizedDescription: LocalizedStringResource {
        switch self {
        case .untracked:
            return LocalizedStringResource("trackingState.untracked")
        case .orientationTracked:
            return LocalizedStringResource("trackingState.orientationTracked")
        case .positionOrientationTracked:
            return LocalizedStringResource("trackingState.positionOrientationTracked")
        case .positionOrientationTrackedLowAccuracy:
            return LocalizedStringResource("trackingState.positionOrientationTrackedLowAccuracy")
        @unknown default:
            return LocalizedStringResource("trackingState.unknown")
        }
    }
}

extension Accessory.Chirality {
    var localizedDescription: LocalizedStringResource {
        switch self {
        case .left:
            return LocalizedStringResource("chirality.left")
        case .right:
            return LocalizedStringResource("chirality.right")
        case .unspecified:
            return LocalizedStringResource("chirality.unspecified")
        @unknown default:
            return LocalizedStringResource("chirality.unknown")
        }
    }
}

extension Bool {
    var localizedYesNo: LocalizedStringResource {
        self ? LocalizedStringResource("status.yes") : LocalizedStringResource("status.no")
    }
}
