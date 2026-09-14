//
//  EntityFactory.swift
//  seeMoteViewer
//
//  Copyright © 2026 seeMote. All rights reserved.
//

import RealityKit
import UIKit

/// 创建 RealityKit 实体与可视化占位。
///
/// RealityKit 的 `Entity`/`ModelEntity` API 要求主 actor，
/// 因此整个工厂标记为 `@MainActor`，与调用方（视图、Tracker）保持一致。
@MainActor
enum EntityFactory {
    private enum Constants {
        static let axisLength: Float = 0.05
        static let axisRadius: Float = 0.002
        static let markerRadius: Float = 0.0025
    }

    /// 创建 RGB 三轴占位实体，用于模型缺失时显示。
    static func makeMissingReferenceEntity() -> Entity {
        let root = Entity()
        let halfLength = Constants.axisLength / 2.0

        let xAxis = makeCylinder(
            height: Constants.axisLength,
            radius: Constants.axisRadius,
            color: .red
        )
        xAxis.position.x = halfLength
        xAxis.transform.rotation = simd_quatf(angle: .pi / 2, axis: [0, 0, 1])
        root.addChild(xAxis)

        let yAxis = makeCylinder(
            height: Constants.axisLength,
            radius: Constants.axisRadius,
            color: .green
        )
        yAxis.position.y = halfLength
        root.addChild(yAxis)

        let zAxis = makeCylinder(
            height: Constants.axisLength,
            radius: Constants.axisRadius,
            color: .blue
        )
        zAxis.position.z = halfLength
        zAxis.transform.rotation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
        root.addChild(zAxis)

        return root
    }

    /// 创建白色小球，用于可视化配件锚点位置。
    static func makeLocationMarkerEntity() -> Entity {
        let material = SimpleMaterial(color: .white, isMetallic: false)
        let mesh = MeshResource.generateSphere(radius: Constants.markerRadius)
        return ModelEntity(mesh: mesh, materials: [material])
    }

    private static func makeCylinder(height: Float, radius: Float, color: UIColor) -> Entity {
        let material = SimpleMaterial(color: color, isMetallic: false)
        let mesh = MeshResource.generateCylinder(height: height, radius: radius)
        return ModelEntity(mesh: mesh, materials: [material])
    }
}

extension Entity {
    /// 循环播放实体的第一个可用动画（通常为 Idle）。
    func playIdleAnimation() {
        guard let animation = availableAnimations.first else { return }
        let looped = animation.repeat(duration: .infinity)
        playAnimation(looped, transitionDuration: 0.3, startsPaused: false)
    }
}
