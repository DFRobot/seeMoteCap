//
//  AnchorManager.swift
//  seeMoteViewer
//
//  Copyright © 2026 seeMote. All rights reserved.
//

import RealityKit

/// 创建与管理配件锚点实体。
@MainActor
enum AnchorManager {
    /// 为指定配件位置创建锚点实体，并附加可视化标记。
    static func createAnchorEntity(
        for source: AnchoringComponent.AccessoryAnchoringSource,
        at location: AnchoringComponent.AccessoryLocation,
        trackingMode: AnchoringComponent.TrackingMode
    ) -> AnchorEntity {
        let anchor = AnchorEntity(
            .accessory(from: source, location: location),
            trackingMode: trackingMode,
            physicsSimulation: .none
        )
        anchor.addChild(EntityFactory.makeLocationMarkerEntity())
        return anchor
    }

    /// 克隆预览实体并应用缩放与空闲动画。
    static func makePreviewClone(from previewEntity: Entity, scale: SIMD3<Float>) -> Entity {
        let clone = previewEntity.clone(recursive: true)
        clone.transform.scale *= scale
        clone.playIdleAnimation()
        return clone
    }

    /// 在配件原点创建参考锚点实体，用于显示预览模型。
    static func createReferenceAnchorEntity(
        for source: AnchoringComponent.AccessoryAnchoringSource,
        trackingMode: AnchoringComponent.TrackingMode,
        previewEntity: Entity,
        scale: SIMD3<Float>
    ) -> AnchorEntity {
        let anchor = AnchorEntity(
            .accessory(from: source, location: .origin),
            trackingMode: trackingMode,
            physicsSimulation: .none
        )

        let clone = makePreviewClone(from: previewEntity, scale: scale)
        anchor.addChild(clone)

        // 设置半透明，避免遮挡真实配件。
        anchor.components.set(OpacityComponent(opacity: 0.5))

        return anchor
    }

    /// 从参考锚点实体中提取内部预览克隆的世界变换。
    ///
    /// - Parameter referenceAnchor: `createReferenceAnchorEntity` 创建的参考锚点。
    /// - Returns: 用于放置复制品的世界变换（包含参考锚点的定位与内部模型的缩放）。
    static func referenceModelWorldTransform(from referenceAnchor: AnchorEntity) -> Transform? {
        guard let referenceModel = referenceAnchor.children.first else { return nil }
        return referenceAnchor.convert(transform: referenceModel.transform, to: nil)
    }
}
