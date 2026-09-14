//
//  PreviewLoader.swift
//  seeMoteViewer
//
//  Copyright © 2026 seeMote. All rights reserved.
//

import SwiftUI
import RealityKit
import os.log

/// 加载预览模型实体。
@MainActor
final class PreviewLoader {
    private let logger = Logger(category: "PreviewLoader")

    enum PreviewModel: String, CaseIterable, Identifiable {
        case accessoryProvided
        case model1
        case model2

        var id: String { rawValue }

        /// 本地化显示名
        var localizedName: LocalizedStringResource {
            switch self {
            case .accessoryProvided:
                return LocalizedStringResource("previewModel.accessoryProvided")
            case .model1:
                return LocalizedStringResource("previewModel.model1")
            case .model2:
                return LocalizedStringResource("previewModel.model2")
            }
        }

        /// 是否需要配件提供 USDZ 文件
        var usesAccessoryModel: Bool {
            self == .accessoryProvided
        }

        /// 显示缩放校准。
        ///
        /// 保持为 `.one`，使空间窗口中的参考模型与复制品始终按 USDZ
        /// 原始尺寸（即实际配件大小）显示。体积预览窗口会单独做窗口适配。
        var displayScale: SIMD3<Float> {
            .one
        }
    }

    func loadPreviewEntity(
        from source: AnchoringComponent.AccessoryAnchoringSource?,
        model: PreviewModel
    ) async -> Entity? {
        var entity: Entity?
        switch model {
        case .model1:
            entity = await loadBundleEntity(named: "acessory2")
        case .model2:
            entity = await loadBundleEntity(named: "acessory3")
        case .accessoryProvided:
            entity = await loadAccessoryEntity(from: source)
        }

        if entity == nil {
            entity = EntityFactory.makeMissingReferenceEntity()
        }
        return entity
    }

    private func loadBundleEntity(named name: String) async -> Entity? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "usdz") else {
            logger.warning("\(name).usdz not found in app bundle.")
            return nil
        }
        do {
            let entity = try await Entity(contentsOf: url)
            logger.info("Loaded \(name).usdz from app bundle.")
            entity.playIdleAnimation()
            return entity
        } catch {
            logger.warning("Failed to load \(name).usdz: \(error)")
            return nil
        }
    }

    private func loadAccessoryEntity(from source: AnchoringComponent.AccessoryAnchoringSource?) async -> Entity? {
        guard let url = source?.underlyingAccessory?.usdzFile else {
            logger.warning("Accessory does not provide a USDZ file.")
            return nil
        }
        do {
            let entity = try await Entity(contentsOf: url)
            logger.info("Loaded accessory USDZ file.")
            return entity
        } catch {
            logger.warning("Failed to load accessory USDZ file: \(error)")
            return nil
        }
    }
}
