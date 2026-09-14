//
//  AccessoryTracker.swift
//  seeMoteViewer
//
//  Copyright © 2026 seeMote. All rights reserved.
//

import ARKit
import RealityKit
@unsafe @preconcurrency import GameController
import os.log

/// 配件追踪外观，暴露视图层需要的统一状态与操作。
@MainActor
@Observable
final class AccessoryTracker {
    let connectionManager = AccessoryConnectionManager()
    let trackingManager = TrackingSessionManager()
    let previewLoader = PreviewLoader()
    let replicaController = ReplicaPlacementController()
    let hapticCoordinator = HapticCoordinator()

    private let logger = Logger(category: "AccessoryTracker")

    var isAccessoryConnected: Bool { connectionManager.isAccessoryConnected }
    var authorizationStatus: ARKitSession.AuthorizationStatus { trackingManager.authorizationStatus }
    var heldChirality: Accessory.Chirality? { trackingManager.heldChirality }
    var isTracked: Bool { trackingManager.isTracked }
    var trackingState: AccessoryAnchor.TrackingState? { trackingManager.trackingState }
    var trackingProviderState: DataProviderState? { trackingManager.trackingProviderState }

    var availableLocations: [AnchoringComponent.AccessoryLocation] = []
    var enabledLocations: Set<AnchoringComponent.AccessoryLocation> = []
    var trackingMode: AnchoringComponent.TrackingMode = .predicted
    var previewModel: PreviewLoader.PreviewModel = .accessoryProvided {
        didSet {
            guard previewModel != oldValue else { return }
            guard let source = currentAnchorSource else { return }
            loadPreview(source: source, model: previewModel)
        }
    }
    var previewEntity: Entity?
    var failedToLoadReferenceAccessory = false
    var accessorySourceLoadError: Error?

    /// 可用追踪模式
    let availableTrackingModes: [AnchoringComponent.TrackingMode] = [.continuous, .predicted]

    private var currentAnchorSource: AnchoringComponent.AccessoryAnchoringSource?
    private let deviceTask = CancellableTask()
    private let previewLoadTask = CancellableTask()

    var supportsHaptics: Bool { hapticCoordinator.supportsHaptics }
    var replicaPlacementSignal: AsyncStream<Void> { replicaController.signal }
    var clearReplicaSignal: AsyncStream<Void> { replicaController.clearSignal }

    init() {
        connectionManager.onDeviceChanged = { [weak self] device in
            Task { @MainActor [weak self] in
                await self?.handleDeviceChange(device)
            }
        }
    }

    /// 加载指定模型。
    private func loadPreview(source: AnchoringComponent.AccessoryAnchoringSource?, model: PreviewLoader.PreviewModel) {
        previewLoadTask.set(Task { [weak self] in
            guard let self else { return }
            let entity = await previewLoader.loadPreviewEntity(from: source, model: model)
            guard !Task.isCancelled else { return }
            guard self.currentAnchorSource == source,
                  self.previewModel == model else { return }
            previewEntity = entity
            if model.usesAccessoryModel && entity == nil {
                failedToLoadReferenceAccessory = true
            }
        })
    }

    /// 显式释放资源；外部持有者在释放 tracker 前应调用一次。
    func teardown() {
        deviceTask.cancel()
        previewLoadTask.cancel()
        hapticCoordinator.stop()
        Task { [weak self] in
            do {
                try await self?.trackingManager.stopTracking()
            } catch {
                self?.logger.error("Failed to stop tracking during teardown: \(error)")
            }
        }
    }

    // MARK: - 位置切换

    func toggleLocation(_ location: AnchoringComponent.AccessoryLocation, enabled: Bool) {
        if enabled {
            enabledLocations.insert(location)
        } else {
            enabledLocations.remove(location)
        }
    }

    // MARK: - 触觉反馈

    func playHaptic(multiPulse: Bool = true) async {
        await hapticCoordinator.play(multiPulse: multiPulse)
    }

    func ensureHapticsRunning() async {
        await hapticCoordinator.ensureRunning(for: connectionManager.connectedDevice)
    }

    // MARK: - 数字复制品

    func triggerReplicaPlacement() {
        guard authorizationStatus == .allowed else { return }
        replicaController.trigger()
    }

    func clearReplicas() {
        replicaController.clearReplicas()
    }

    // MARK: - 锚点源

    func createAnchorSource() async -> AnchoringComponent.AccessoryAnchoringSource? {
        guard let device = connectionManager.connectedDevice else { return nil }
        if let source = currentAnchorSource { return source }
        do {
            let source = try await AnchoringComponent.AccessoryAnchoringSource(device: device)
            currentAnchorSource = source
            return source
        } catch {
            logger.error("Failed to create anchor source: \(error)")
            return nil
        }
    }

    // MARK: - 最新锚点查询

    func fetchLatestAnchor() -> AccessoryAnchor? {
        trackingManager.fetchLatestAnchor(trackingMode: trackingMode)
    }

    // MARK: - 设备变化处理

    private func handleDeviceChange(_ device: GCSpatialAccessory?) async {
        availableLocations = []
        enabledLocations = []
        currentAnchorSource = nil
        previewEntity = nil
        previewLoadTask.cancel()
        accessorySourceLoadError = nil
        if device == nil {
            previewModel = .accessoryProvided
        }
        failedToLoadReferenceAccessory = false
        hapticCoordinator.stop()
        do {
            try await trackingManager.stopTracking()
        } catch {
            logger.error("Failed to stop tracking on device change: \(error)")
        }
        deviceTask.cancel()

        guard let device else { return }

        device.input?.elementValueDidChangeHandler = { [weak self] (_, element) in
            guard let self else { return }
            if let button = element as? GCButtonElement,
               button.pressedInput.isPressed {
                triggerReplicaPlacement()
            }
        }

        deviceTask.set(Task { [weak self] in
            guard let self else { return }
            do {
                let source = try await AnchoringComponent.AccessoryAnchoringSource(device: device)
                guard !Task.isCancelled else { return }
                currentAnchorSource = source
                availableLocations = source.accessoryLocations
                enabledLocations = Set(source.accessoryLocations)
                accessorySourceLoadError = nil
                loadPreview(source: source, model: previewModel)
            } catch is CancellationError {
                return
            } catch {
                accessorySourceLoadError = error
                logger.error("Failed to set up accessory device: \(error)")
            }
            await hapticCoordinator.ensureRunning(for: device)
            await trackingManager.startTracking(for: device)
        })
    }
}

extension AccessoryTracker {
    /// 当前预览实体的唯一标识，用于在多个视图中统一决定是否需要重建/更新。
    var previewEntityID: ObjectIdentifier? {
        previewEntity.map(ObjectIdentifier.init)
    }
}
